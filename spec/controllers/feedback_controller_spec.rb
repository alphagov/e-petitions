require 'rails_helper'

describe FeedbackController do
  with_ssl do
    describe "GET 'index'" do
      it "should be successful" do
        get 'index'
        response.should be_success
      end
    end

    describe "GET 'create'" do
      let(:feedback) { double.as_null_object }
      before(:each) { Feedback.stub(:new => feedback) }

      context "valid input" do
        before(:each) { feedback.stub(:valid? => true) }

        it "is successful" do
          post 'create', :feedback => {}
          response.should redirect_to(thanks_feedback_path)
        end

        it "sends an email" do
          FeedbackMailer.should_receive(:send_feedback).with(feedback).and_return(double.as_null_object)
          post 'create', :feedback => {}
        end
      end

      context "invalid input" do
        before(:each) { feedback.stub(:valid? => false) }

        it "does not send an email" do
          FeedbackMailer.should_not_receive(:send_feedback)
          post 'create', :feedback => {}
        end

        it "returns the user to the form" do
          post 'create', :feedback => {}
          response.should render_template("feedback/index")
        end
      end
    end

    describe "GET 'thanks'" do
      it "should be successful" do
        get 'thanks'
        response.should be_success
      end
    end

  end
end
