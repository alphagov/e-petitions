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

    def reset!
      connection.execute "TRUNCATE TABLE trending_petition_journals"

      Petition.find_each do |petition|
        petition.signatures.validated_dates.each do |date|
          journal = self.for(petition, date)

          journal.with_lock do
            updates = petition
              .signatures
              .validated
              .select("count(petition_id), EXTRACT(hour from validated_at) as hour")
              .where("date(validated_at) = ?", date)
              .group("hour")
              .each_with_object({}) do |interval, updates|
                updates["hour_#{interval.hour.to_i}_signature_count"] = interval.count
              end

            journal.update_columns(updates.merge(updated_at: Time.current))
          end
        end
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
