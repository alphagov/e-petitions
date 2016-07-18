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

    def record_new_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        journal = self.for(signature.petition, signature.location_code)
        updates = "signature_count = signature_count + 1, updated_at = :now"
        unscoped.where(id: journal.id).update_all([updates, now: now])
      end
    end

    def invalidate_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        journal = self.for(signature.petition, signature.location_code)
        updates = "signature_count = greatest(signature_count - 1, 0), updated_at = :now"
        unscoped.where(id: journal.id).update_all([updates, now: now])
      end
    end

    def reset!
      # NOTE: location_code <> '' is the closest we can (performantly) get to rails'
      # String#blank? in SQL
      connection.execute 'TRUNCATE TABLE country_petition_journals'
      connection.execute <<-SQL.strip_heredoc
        INSERT INTO country_petition_journals
          (petition_id, location_code, signature_count, created_at, updated_at)
        SELECT
          petition_id, location_code, COUNT(*) AS signature_count,
          timezone('utc', now()), timezone('utc', now())
        FROM signatures
        WHERE state = 'validated'
        AND location_code <> ''
        GROUP BY petition_id, location_code
      SQL
    end

    private

    def unrecordable?(signature)
      signature.nil? || signature.petition.nil? || signature.location_code.blank? || !signature.validated_at?
    end
  end
end
