require 'rails_helper'

RSpec.describe TrackersController, type: :controller do
  describe "GET /petition/:petition_id/trackers/:id.gif" do
    let(:current_time) { Time.utc(2019, 4, 14, 16, 0, 0) }
    let(:form_token) { "S7lqpOv8zEvROaq3bJE8" }

    let(:form_request) do
      { "form_requested_at" => current_time.iso8601(0), "form_token" => form_token }
    end

    before do
      allow(Petition).to receive_message_chain(:visible, :find).with(1).and_return(petition)
    end

    around do |example|
      travel_to(current_time) { example.run }
    end

    shared_examples_for "a tracking controller" do
      before do
        session[:form_requests] = { "1" => form_request }
        get :show, petition_id: "1", id: "S7lqpOv8zEvROaq3bJE8", format: "gif"
      end

      it "assigns the @petition instance variable" do
        expect(assigns[:petition]).to eq(petition)
      end

      it "sets an encrypted cookie using the id parameter" do
        expect(cookies.encrypted["S7lqpOv8zEvROaq3bJE8"]).to eq("2019-04-14T16:00:00Z")
      end

      it "renders the trackers/show template" do
        expect(response).to render_template("trackers/show")
      end

      it "returns a GIF image" do
        expect(response.content_type).to eq("image/gif")
      end

      it "sets the Cache-Control header" do
        expect(response.headers["Cache-Control"]).to eq("no-store, no-cache")
      end
    end

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }

      it_behaves_like "a tracking controller"
    end

    context "when the petition is recently closed" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: 12.hours.ago) }

      it_behaves_like "a tracking controller"
    end

    context "when the path token doesn't match the session token" do
      let(:petition) { FactoryBot.create(:open_petition) }

      it "returns a 400 Bad Request response" do
        expect {
          get :show, petition_id: "1", id: "wYonHKjTeW7mtTusqDv", format: "gif"
        }.to raise_error(ActionController::BadRequest)
      end
    end

    context "when the petition is closed" do
      let(:petition) { FactoryBot.create(:closed_petition) }

      it "returns a 400 Bad Request response" do
        expect {
          get :show, petition_id: "1", id: "S7lqpOv8zEvROaq3bJE8", format: "gif"
        }.to raise_error(ActionController::BadRequest)
      end
    end

    context "when the petition is rejected" do
      let(:petition) { FactoryBot.create(:rejected_petition) }

      it "returns a 400 Bad Request response" do
        expect {
          get :show, petition_id: "1", id: "S7lqpOv8zEvROaq3bJE8", format: "gif"
        }.to raise_error(ActionController::BadRequest)
      end
    end
  end
end
