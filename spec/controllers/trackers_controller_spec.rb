require 'rails_helper'

RSpec.describe TrackersController, type: :controller do
  describe "GET /trackers/:id.gif" do
    let(:current_time) { Time.utc(2019, 4, 14, 16, 0, 0) }

    before do
      travel_to current_time do
        get :show, id: "S7lqpOv8zEvROaq3bJE8", format: "gif"
      end
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
  end
end
