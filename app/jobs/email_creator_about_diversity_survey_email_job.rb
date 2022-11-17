class EmailCreatorAboutDiversitySurveyEmailJob < NotifyJob
  self.template = :email_creator_about_diversity_survey

  def personalisation(signature, petition)
    {
      creator: signature.name
    }
  end
end
