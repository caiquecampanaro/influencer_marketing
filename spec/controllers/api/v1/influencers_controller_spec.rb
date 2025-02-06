# spec/controllers/api/v1/influencers_controller_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::InfluencersController, type: :controller do
  describe "GET #sync" do
    it "syncs influencers from external API and returns a success message" do
      allow(Faraday).to receive(:get).and_return(double("response", status: 200, body: '[{"username": "johndoe123", "name": "John Doe", "email": "john.doe@example.com"}]'))

      get :sync

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Influencers synced successfully")
    end

    it "returns an error message when the external API request fails" do
      allow(Faraday).to receive(:get).and_return(double("response", status: 500, body: ''))

      get :sync

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Failed to fetch data from external API")
    end
  end
end
