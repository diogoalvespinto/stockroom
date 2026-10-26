require "rails_helper"

RSpec.describe "health check", type: :request do
  describe "GET /up" do
    it "responds with 200 ok" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end
  end
end
