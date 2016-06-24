class CachedSignatureCountResetJob < ActiveJob::Base
  queue_as :highest_priority

  def perform
    Petition.updated_since(timestamp).each do |petition|
      petition.save_cached_signature_count
    end
  end

  private

  def timestamp
    Site.signature_count_updated_since_window.ago - 1.minute
  end
end
