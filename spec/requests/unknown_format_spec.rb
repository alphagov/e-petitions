require 'rails_helper'

RSpec.describe "Requests for an unknown format", type: :request, show_exceptions: true do
  let!(:petition) { FactoryBot.create(:open_petition, id: 100001) }

  context "when the url has an extension" do
    before do
      get "/petitions/100001.please"
    end

    it "redirect to the path without the extension" do
      expect(response).to redirect_to("/petitions/100001")

      follow_redirect!

      expect(response).to have_http_status(:ok)
    end
  end

  context "when the url has no extension" do
    before do
      get "/petitions/100001", headers: { "Accept" => "application/please" }
    end

    it "responds with 406 Not Acceptable" do
      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
