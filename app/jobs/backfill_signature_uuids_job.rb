class BackfillSignatureUuidsJob < ApplicationJob
  queue_as :low_priority

  def perform(id = 0)
    signatures = Signature.where(uuid: nil).batch(id).to_a
    max_id = signatures.map(&:id).max

    signatures.each do |signature|
      next if signature.uuid?

      if signature.email?
        signature.update_uuid
      end
    end

    if Signature.exists?(uuid: nil)
      self.class.perform_later(max_id)
    end
  end
end
