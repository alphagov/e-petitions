class EmailCreatorAboutOtherBusinessEmailJob < NotifyJob
  self.template = :email_creator_about_other_business

  def perform(signature, *args)
    if signature.notify_by_email?
      super
    end
  end

  def personalisation(signature, petition, email)
    {
      name: signature.name,
      action_en: petition.action_en, action_cy: petition.action_cy,
      petition_url_en: petition_en_url(petition),
      petition_url_cy: petition_cy_url(petition),
      subject_en: email.subject_en, subject_cy: email.subject_cy,
      body_en: email.body_en, body_cy: email.body_cy,
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_cy: unsubscribe_signature_cy_url(signature, token: signature.unsubscribe_token),
    }
  end
end
