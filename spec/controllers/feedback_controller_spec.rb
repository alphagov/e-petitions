require 'rails_helper'

RSpec.describe FeedbackController, type: :controller do
  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'create'" do
    let(:feedback) { double.as_null_object }
    before(:each) { allow(Feedback).to receive_messages(:new => feedback) }

    context "valid input" do
      before(:each) { allow(feedback).to receive_messages(:valid? => true) }

      it "is successful" do
        post 'create', :feedback => {}
        expect(response).to redirect_to("https://petition.parliament.uk/feedback/thanks")
      end

      it "sends an email" do
        expect(FeedbackMailer).to receive(:send_feedback).with(feedback).and_return(double.as_null_object)
        post 'create', :feedback => {}
      end
    end

    context "invalid input" do
      before(:each) { allow(feedback).to receive_messages(:valid? => false) }

      it "does not send an email" do
        expect(FeedbackMailer).not_to receive(:send_feedback)
        post 'create', :feedback => {}
      end

      it "returns the user to the form" do
        post 'create', :feedback => {}
        expect(response).to render_template("feedback/index")
      end
    end
  end

  describe "GET 'thanks'" do
    it "should be successful" do
      get 'thanks'
      expect(response).to be_success
    end
  end
end
