class CachedPetitionValuesResetJob < ActiveJob::Base
  queue_as :highest_priority

  def perform
    Petition.updated_since(timestamp).each do |petition|
      petition.save_cached_values_to_db
    end
  end

  private

  def timestamp
    Site.petition_caches_updated_since_window.ago - 1.minute
  end
end

# alias the new class to the old one, just in case there are
# any old jobs lying around
CachedSignatureCountResetJob = CachedPetitionValuesResetJob
