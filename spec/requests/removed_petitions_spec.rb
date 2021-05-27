require 'rails_helper'

RSpec.describe "Removed petitions", type: :request, show_exceptions: true do
  context "When requesting a petition that has been hidden after opening" do
    let(:petition) { FactoryBot.create(:hidden_petition, open_at: 1.month.ago) }

    it "returns a 410 Gone response" do
      get "/petitions/#{petition.id}"
      expect(response).to have_http_status(:gone)
    end
  end

  context "When requesting an archived petition that has been hidden after opening" do
    let(:petition) { FactoryBot.create(:archived_petition, :hidden, open_at: 3.years.ago) }

    it "returns a 410 Gone response" do
      get "/archived/petitions/#{petition.id}"
      expect(response).to have_http_status(:gone)
    end
  end
end
