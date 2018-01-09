require 'rails_helper'

RSpec.describe SurveyMailer, type: :mailer do
  describe "send_survey" do
    let(:email_address) { "graham@example.com" }
    let(:subject_text) { "Exploratory Survey" }
    let(:body_text) { "Please fill in our survey at https://www.example.com/path_to_survey" }

    let(:survey) { FactoryBot.create :survey, subject: subject_text, body: body_text }

    let(:mail) { described_class.send_survey(email_address, survey) }

    it "sends the email to the supplied address" do
      expect(mail.to).to eq [email_address]
    end

    it "renders the survey subject" do
      expect(mail.subject).to eq subject_text
    end

    it "renders the survey body" do
      expect(mail).to have_body_text(body_text)
    end
  end
end
