class SurveyMailer < ApplicationMailer
  def send_survey(email, survey)
    mail to: email,
      subject: survey.subject,
      body: survey.body
  end
end
