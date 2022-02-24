class DeliverPrivacyPolicyUpdateJob < EmailJob
  queue_as :low_priority

  self.mailer = PetitionMailer
  self.email = :privacy_policy_update_email
end
