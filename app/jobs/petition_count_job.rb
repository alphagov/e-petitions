class PetitionCountJob < ActiveJob::Base
  class InvalidSignatureCounts < RuntimeError; end

  def perform
    petitions = Petition.with_invalid_signature_counts

    unless petitions.empty?
      petitions.each(&:update_signature_count!)

      Appsignal.send_exception(exception(petitions))
    end
  end

  private

  def exception(petitions)
    InvalidSignatureCounts.new(error_message(petitions))
  end

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
