require 'rails_helper'

RSpec.describe FeedbackMailer, type: :mailer do
  describe "send_feedback" do
    let(:email) { "foo@example.com" }
    let(:comment) { "I love your site!" }
    let(:title) { nil }

    let(:feedback) do
      Feedback.new(
        email: email,
        comment: comment,
        petition_link_or_title: title,
        user_agent: "Mozilla/5.0",
        ip_address: "192.168.12.34"
      )
    end

    subject(:mail) { FeedbackMailer.send_feedback(feedback) }

    it "renders the headers" do
      expect(mail).to have_subject("Feedback from the Petitions service")
    end

    it "renders the body" do
      expect(mail).to have_body_text("I love your site!")
    end

    it "sets the reply-to to be the email address" do
      expect(mail.reply_to).to eq(["foo@example.com"])
    end

    it "renders the browser user agent string" do
      expect(mail).to have_body_text("Mozilla/5.0")
    end

    it "renders the remote ip address" do
      expect(mail).to have_body_text("192.168.12.34")
    end

    context "when the comment field contains line breaks" do
      let(:comment) { "Line 1\nLine 2\n\nLine 3" }

      it "converts the line breaks to HTML" do
        expect(mail.html).to match("<p>Line 1\n<br>Line 2</p>\n\n<p>Line 3</p>")
      end
    end

    context "when the comment field contains HTML" do
      let(:comment) { '<img src="meme.jpg">' }

      it "escapes the comment" do
        expect(mail.html).to match('&lt;img src="meme.jpg"&gt;')
      end
    end

    context "when the comment field contains a URL" do
      let(:comment) { "https://www.example.com" }

      it "creates a link" do
        expect(mail.html).to match('<a href="https://www.example.com">https://www.example.com</a>')
      end
    end

    context "when the petition link or title contains a petition url" do
      let(:title) { "https://petition.parliament.uk/petitions/200000" }

      it "creates a link to the petition" do
        expect(mail.html).to match('<a href="https://petition.parliament.uk/petitions/200000">https://petition.parliament.uk/petitions/200000</a>')
      end
    end

    context "when the petition link or title contains an external url" do
      let(:title) { "https://www.example.com" }

      it "doesn't link the url" do
        expect(mail.html).not_to match('<a href="https://www.example.com">https://www.example.com</a>')
      end
    end
  end
end
