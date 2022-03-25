class CountryPetitionJournal < ActiveRecord::Base
  UK_COUNTRIES = {
    'GB-ENG' => 'E92000001',
    'GB-NIR' => 'N92000002',
    'GB-SCT' => 'S92000003',
    'GB-WLS' => 'W92000004'
  }

  belongs_to :petition

  validates :petition, presence: true
  validates :location_code, presence: true, inclusion: { in: :location_codes }
  validates :signature_count, presence: true

  class << self
    def for(petition, location_code)
      begin
        find_or_create_by(petition: petition, location_code: location_code)
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end

    def older_than(time)
      where(last_signed_at.lt(time).or(last_signed_at.eq(nil)))
    end

    def increment_signature_counts_for(petition, since)
      signature_counts(petition, since).each do |location_code, count|
        next if location_code.blank?
        self.for(petition, location_code).increment_signature_count(count, petition)
      end
    end

    def reset_signature_counts_for(petition)
      signature_counts(petition).each do |location_code, count|
        next if location_code.blank?
        self.for(petition, location_code).reset_signature_count(count, petition)
      end

      petition.country_petition_journals.older_than(petition.last_signed_at).delete_all
    end

    def invalidate_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        self.for(signature.petition, signature.location_code).decrement_signature_count(now)
      end
    end

    def uk
      where(location_code: UK_COUNTRIES.keys)
    end

    private

    def last_signed_at
      arel_table[:last_signed_at]
    end

    def unrecordable?(signature)
      signature.nil? || signature.petition.nil? || signature.location_code.blank? || !signature.validated_at?
    end

    def signature_counts(petition, since = nil)
      petition.signatures.validated_count_by_location_code(since, petition.last_signed_at)
    end
  end

  def increment_signature_count(count, petition)
    sql = "signature_count = signature_count + ?, last_signed_at = ?, updated_at = ?"
    update_all([sql, count, petition.last_signed_at, petition.updated_at])
  end

  def reset_signature_count(count, petition)
    sql = "signature_count = ?, last_signed_at = ?, updated_at = ?"
    update_all([sql, count, petition.last_signed_at, petition.updated_at])
  end

  def decrement_signature_count(now = Time.current, count = 1)
    sql = "signature_count = greatest(signature_count - ?, 0), updated_at = ?"
    update_all([sql, count, now])
  end

  def code
    location_code
  end

  def ons_code
    UK_COUNTRIES.fetch(location_code)
  end

  def name
    I18n.t(location_code, scope: :country_name)
  end

  private

  def location_codes
    priority_country_codes + country_codes
  end

  def priority_country_codes
    I18n.t(:priority_countries, default: []).map(&:last)
  end

  def country_codes
    I18n.t(:countries, default: []).map(&:last)
  end

  def update_all(updates)
    self.class.unscoped.where(id: id).update_all(updates)
  end
end
