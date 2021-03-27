class ConstituencyPetitionJournal < ActiveRecord::Base
  belongs_to :petition
  belongs_to :constituency, optional: true

  validates :petition, presence: true
  validates :constituency_id, presence: true, length: { maximum: 255 }
  validates :signature_count, presence: true

  delegate :name, :region_id, :region, to: :constituency

  class << self
    def for(petition, constituency_id)
      begin
        find_or_create_by(petition: petition, constituency_id: constituency_id)
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end

    def older_than(time)
      where(last_signed_at.lt(time).or(last_signed_at.eq(nil)))
    end

    def ordered
      order(signature_count: :desc)
    end

    def increment_signature_counts_for(petition, since)
      signature_counts(petition, since).each do |constituency_id, count|
        next if constituency_id.blank?
        self.for(petition, constituency_id).increment_signature_count(count, petition)
      end
    end

    def reset_signature_counts_for(petition)
      signature_counts(petition).each do |constituency_id, count|
        next if constituency_id.blank?
        self.for(petition, constituency_id).reset_signature_count(count, petition)
      end

      petition.constituency_petition_journals.older_than(petition.last_signed_at).delete_all
    end

    def invalidate_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        self.for(signature.petition, signature.constituency_id).decrement_signature_count(now)
      end
    end

    def with_signatures_for(constituency_id)
      where(arel_table[:signature_count].gt(0)).where(arel_table[:constituency_id].eq(constituency_id))
    end

    private

    def last_signed_at
      arel_table[:last_signed_at]
    end

    def unrecordable?(signature)
      signature.nil? || signature.petition.nil? || signature.constituency_id.blank? || !signature.validated_at?
    end

    def signature_counts(petition, since = nil)
      petition.signatures.validated_count_by_constituency_id(since, petition.last_signed_at)
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
