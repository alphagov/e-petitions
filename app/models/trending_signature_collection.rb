class TrendingSignatureCollection
  HOURS = (0..23)

  def initialize(petition)
    @petition = petition
  end

  def hourly_intervals
    Enumerator.new do |yielder|
      signature_dates.each do |date|
        HOURS.each do |hour|
          starts_at = date.to_time.change(hour: hour)
          ends_at = date.to_time.change(hour: hour + 1)

          yielder << SignatureInterval.new(
            starts_at: starts_at, ends_at: ends_at, count: signature_count(date, hour)
          ) unless starts_at.future?
        end
      end
    end
  end

  private

  attr_reader :petition

  def signature_dates
    if trending_petition_journals.any?
      (first_signature_date..last_signature_date)
    else
      []
    end
  end

  def journal(date)
    trending_petition_journals.find do |journal|
      journal.date == date
    end || TrendingPetitionJournal.new
  end

  def signature_count(date, hour)
    journal(date).public_send("hour_#{hour}_signature_count")
  end

  def trending_signature_dates
    trending_petition_journals.map(&:date)
  end

  def first_signature_date
    trending_signature_dates.first
  end

  def last_signature_date
    trending_signature_dates.last
  end

  def trending_petition_journals
    @_trending_petition_journals ||= petition.trending_petition_journals.order(:date)
  end
end
