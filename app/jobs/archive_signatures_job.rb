class ArchiveSignaturesJob < ApplicationJob
  queue_as :high_priority

  def perform(petition, archived_petition, limit: 1000)
    last_id = petition.signatures.maximum(:id)
    next_id = 0

    while next_id < last_id
      signature_ids = petition.signatures.batch(next_id, limit: limit).pluck(:id)
      next_id = signature_ids.max

      ArchiveSignatureJob.perform_later(petition, archived_petition, signature_ids)
    end
  end
end
