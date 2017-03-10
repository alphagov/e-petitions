class TrendingPetitionJournal < ActiveRecord::Base
  belongs_to :petition

  validates :petition, presence: true
  validates :date, presence: true

  class << self
    def for(petition, date = Date.current)
      begin
        find_or_create_by(
          petition: petition,
          date: date
        )
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end

    def record_new_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        journal = self.for(signature.petition, signature.validated_at.to_date)
        count_column = signature_count_column(signature)
        updates = "#{count_column} = #{count_column} + 1, updated_at = :now"
        unscoped.where(id: journal.id).update_all([updates, now: now])
      end
    end

    def invalidate_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        journal = self.for(signature.petition, signature.validated_at.to_date)
        count_column = signature_count_column(signature)
        updates = "#{count_column} = greatest(#{count_column} - 1, 0), updated_at = :now"
        unscoped.where(id: journal.id).update_all([updates, now: now])
      end
    end

    private

    def unrecordable?(signature)
      signature.nil? || signature.petition.nil? || !signature.validated_at?
    end

    def signature_count_column(signature)
      "hour_#{signature.validated_at.strftime('%-k')}_signature_count"
    end
  end
end
