require 'rails_helper'

RSpec.describe PingController, type: :controller do
  describe "ping" do
    it "should respond to the /ping path" do
      expect({:get => "/ping"}).to route_to({:controller => "ping", :action => "ping"})
    end

    context "fetching ping" do
      before { get :ping }

      it "should return the correct body" do
        expect(response.body).to eq("PONG")
      end

      it "should return with OK http status" do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
