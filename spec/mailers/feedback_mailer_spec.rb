require 'rails_helper'

RSpec.describe FeedbackMailer, type: :mailer do
  describe "send_feedback" do
    let(:feedback) { Feedback.new(:email => "foo@example.com", :comment => "I love your site!") }
    let(:mail) { FeedbackMailer.send_feedback(feedback) }

    it "renders the headers" do
      expect(mail.subject).to eq("Feedback from the Petitions service")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(feedback.comment)
    end

    it "sets the reply-to to be the email address" do
      expect(mail.reply_to).to eq([feedback.email])
    end
  end

end
