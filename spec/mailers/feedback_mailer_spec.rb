require 'rails_helper'

describe FeedbackMailer do
  describe "send_feedback" do
    let(:feedback) { Feedback.new(:email => "foo@example.com", :comment => "I love your site!") }
    let(:mail) { FeedbackMailer.send_feedback(feedback) }

    it "renders the headers" do
      mail.subject.should eq("e-petitions: Feedback received")
    end

    it "renders the body" do
      mail.body.encoded.should match(feedback.comment)
    end

    it "sets the reply-to to be the email address" do
      mail.reply_to.should == [feedback.email]
    end
  end

end
