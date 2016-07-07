class ConstituencyPetitionJournal < ActiveRecord::Base
  belongs_to :petition
  belongs_to :constituency, primary_key: :external_id

  validates :petition, presence: true
  validates :constituency_id, presence: true, length: { maximum: 255 }
  validates :signature_count, presence: true

  delegate :name, :ons_code, :mp_name, to: :constituency

  class << self
    def for(petition, constituency_id)
      begin
        find_or_create_by(petition: petition, constituency_id: constituency_id)
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end

    def ordered
      order(signature_count: :desc)
    end

    def record_new_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        journal = self.for(signature.petition, signature.constituency_id)
        updates = "signature_count = signature_count + 1, updated_at = :now"
        unscoped.where(id: journal.id).update_all([updates, now: now])
      end
    end

    def invalidate_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        journal = self.for(signature.petition, signature.constituency_id)
        updates = "signature_count = greatest(signature_count - 1, 0), updated_at = :now"
        unscoped.where(id: journal.id).update_all([updates, now: now])
      end
    end

    def reset!
      connection.execute "TRUNCATE TABLE #{self.table_name}"
      connection.execute <<-SQL.strip_heredoc
        INSERT INTO #{self.table_name}
          (petition_id, constituency_id, signature_count, created_at, updated_at)
        SELECT
          petition_id, constituency_id, COUNT(*) AS signature_count,
          timezone('utc', now()), timezone('utc', now())
        FROM signatures
        WHERE state = 'validated'
        AND constituency_id IS NOT NULL
        GROUP BY petition_id, constituency_id
      SQL
    end

    def with_signatures_for(constituency_id)
      where(arel_table[:signature_count].gt(0)).where(arel_table[:constituency_id].eq(constituency_id))
    end

    private

    def unrecordable?(signature)
      signature.nil? || signature.petition.nil? || signature.constituency_id.blank? || !signature.validated_at?
    end
  end
end
