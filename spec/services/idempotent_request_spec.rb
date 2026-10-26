require "rails_helper"

RSpec.describe IdempotentRequest do
  let(:user) { create(:user) }

  def request(key: "k-1", fingerprint: "abc", user: self.user, &operation)
    described_class.new(user: user, key: key, fingerprint: fingerprint).call(&operation)
  end

  it "runs the operation and remembers its response" do
    result = request { [ 201, '{"ok":true}' ] }

    expect(result).to have_attributes(status: 201, body: '{"ok":true}', replayed: false)
    expect(IdempotencyKey.sole).to have_attributes(key: "k-1", response_status: 201, response_body: '{"ok":true}')
  end

  it "replays the stored response without running the operation again" do
    request { [ 201, '{"ok":true}' ] }
    runs = 0

    result = request { runs += 1 }

    expect(runs).to eq(0)
    expect(result).to have_attributes(status: 201, body: '{"ok":true}', replayed: true)
  end

  it "refuses a known key with a different fingerprint" do
    request { [ 201, "{}" ] }

    expect { request(fingerprint: "other") { [ 201, "{}" ] } }.to raise_error(IdempotentRequest::KeyReused)
  end

  it "forgets the key when the operation fails" do
    expect { request { raise Stock::InsufficientStock.new(requested: 2, available: 1) } }
      .to raise_error(Stock::InsufficientStock)

    expect(IdempotencyKey.count).to eq(0)
  end

  context "with concurrent requests" do
    include_context "with committed data"

    it "runs the operation once when two requests share a key" do
      user = create(:user)
      inside_operation = Concurrent::CyclicBarrier.new(2)
      runs = Concurrent::AtomicFixnum.new

      results = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            request(user: user) do
              runs.increment
              inside_operation.wait(1)
              [ 201, '{"ok":true}' ]
            end
          end
        end
      end.map(&:value)

      expect(runs.value).to eq(1)
      expect(results.map(&:body)).to all(eq('{"ok":true}'))
      expect(results.map(&:replayed)).to contain_exactly(false, true)
    end
  end
end
