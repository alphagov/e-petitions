class CountryPetitionJournal < ActiveRecord::Base
  belongs_to :petition
  belongs_to :location, foreign_key: :location_code, primary_key: :code

  validates :petition, presence: true
  validates :location, presence: true
  validates :signature_count, presence: true

  delegate :name, :code, to: :location

  class << self
    def for(petition, location_code)
      begin
        find_or_create_by(petition: petition, location_code: location_code)
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end

    def increment_signature_counts_for(petition, since)
      signature_counts(petition, since).each do |location_code, count|
        next if location_code.blank?
        self.for(petition, location_code).increment_signature_count(count, petition)
      end
    end

    def reset_signature_counts_for(petition)
      petition.country_petition_journals.delete_all

      signature_counts(petition).each do |location_code, count|
        next if location_code.blank?
        self.for(petition, location_code).reset_signature_count(count, petition)
      end
    end

    def invalidate_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        self.for(signature.petition, signature.location_code).decrement_signature_count(now)
      end
    end

    private

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

  private

  def update_all(updates)
    self.class.unscoped.where(id: id).update_all(updates)
  end
end
