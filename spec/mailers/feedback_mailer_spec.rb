require 'rails_helper'

RSpec.describe FeedbackMailer, type: :mailer do
  describe "send_feedback" do
    let(:feedback) { Feedback.new(:email => "foo@example.com", :comment => "I love your site!") }
    let(:mail) { FeedbackMailer.send_feedback(feedback) }

    it "renders the headers" do
      expect(mail).to have_subject("Feedback from the Petitions service")
    end

    it "renders the body" do
      expect(mail).to have_body_text(feedback.comment)
    end

    it "sets the reply-to to be the email address" do
      expect(mail.reply_to).to eq([feedback.email])
    end
  end
end
