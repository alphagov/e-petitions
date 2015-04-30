require 'rails_helper'

describe FeedbackMailer do
  describe "send_feedback" do
    let(:feedback) { Feedback.new(:email => "foo@example.com", :comment => "I love your site!") }
    let(:mail) { FeedbackMailer.send_feedback(feedback) }

    it "renders the headers" do
      expect(mail.subject).to eq("e-petitions: Feedback received")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(feedback.comment)
    end

    it "sets the reply-to to be the email address" do
      expect(mail.reply_to).to eq([feedback.email])
    end
  end

end
