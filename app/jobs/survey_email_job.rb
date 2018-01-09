class SurveyEmailJob < EmailJob
  self.mailer = SurveyMailer
  self.email = :send_survey
end
