require "rails_helper"
require "rake"

RSpec.describe "api_tokens:create" do
  subject(:task) { Rake::Task["api_tokens:create"] }

  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("api_tokens:create") }

  after { task.reenable }

  it "creates a named token for the user and prints it" do
    user = create(:user, email_address: "ana@example.com")
    stub_const("ENV", ENV.to_h.merge("EMAIL" => "ana@example.com", "NAME" => "warehouse scanner"))
    printed = nil
    allow($stdout).to receive(:puts) { |token| printed = token }

    task.invoke

    expect(ApiToken.authenticate(printed)).to have_attributes(user: user, name: "warehouse scanner")
  end

  it "fails for an unknown email address" do
    stub_const("ENV", ENV.to_h.merge("EMAIL" => "nobody@example.com"))

    expect { task.invoke }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
