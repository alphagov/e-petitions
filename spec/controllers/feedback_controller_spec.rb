require 'rails_helper'

RSpec.describe FeedbackController, type: :controller do
  describe "GET /feedback" do
    it "is successful" do
      get :new
      expect(response).to be_success
    end
  end

  describe "POST /feedback" do
    def do_post(attributes = {})
      perform_enqueued_jobs do
        post :create, params: { feedback: attributes }
      end
    end

    context "with valid input" do
      it "is successful" do
        do_post comment: "This website is great!"
        expect(response).to redirect_to("https://petition.parliament.uk/feedback/thanks")
      end

      it "sends an email" do
        expect {
          do_post comment: "This website is great!"
        }.to change{ ActionMailer::Base.deliveries.size }.by(1)
      end
    end

    context "with invalid input" do
      it "does not send an email" do
        expect {
          do_post comment: ""
        }.not_to change{ ActionMailer::Base.deliveries.size }
      end

      it "returns the user to the form" do
        do_post comment: ""
        expect(response).to render_template("feedback/new")
      end
    end
  end

  describe "GET /feedback/thanks" do
    it "is successful" do
      get :thanks
      expect(response).to be_success
    end
  end
end
