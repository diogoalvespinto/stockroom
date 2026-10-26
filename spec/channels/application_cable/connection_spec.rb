require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "identifies the user from the session cookie" do
    session = create(:session)
    cookies.signed[:session_id] = session.id

    connect "/cable"

    expect(connection.current_user).to eq(session.user)
  end

  it "rejects a connection without a session" do
    expect { connect "/cable" }.to have_rejected_connection
  end
end
