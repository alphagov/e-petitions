class BackfillCanonicalEmailsJob < ApplicationJob
  queue_as :low_priority

  def perform(id = 0)
    signatures = Signature.where(canonical_email: nil).batch(id).to_a
    max_id = signatures.map(&:id).max

    signatures.each do |signature|
      next if signature.canonical_email?

      if signature.email?
        signature.update_canonical_email
      end
    end

    if Signature.exists?(canonical_email: nil)
      self.class.perform_later(max_id)
    end
  end
end
