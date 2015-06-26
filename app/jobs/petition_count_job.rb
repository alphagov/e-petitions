class PetitionCountJob < ActiveJob::Base
  def perform
    petitions = Petition.with_invalid_signature_counts

    unless petitions.empty?
      petitions.each(&:update_signature_count!)
      NewRelic::Agent.notice_error(error_message(petitions))
    end
  end

  private

  def error_message(petitions)
    I18n.t(
      :"invalid_signature_counts",
        scope:  :"petitions.errors",
        count:  petitions.size,
        ids:    petitions.map(&:id).inspect,
        id:     petitions.first.id.to_s
    )
  end
end
