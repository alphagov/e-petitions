class CountryPetitionJournal < ActiveRecord::Base
  belongs_to :petition

  validates :petition, presence: true
  validates :country, presence: true, length: { maximum: 255 }
  validates :signature_count, presence: true

  alias_attribute :name, :country

  class << self
    def for(petition, country)
      begin
        find_or_create_by(petition: petition, country: country)
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end

    def record_new_signature_for(signature, now = Time.current)
      unless unrecordable?(signature)
        journal = self.for(signature.petition, signature.country)
        updates = "signature_count = signature_count + 1, updated_at = :now"
        unscoped.where(id: journal.id).update_all([updates, now: now])
      end
    end

    def reset!
      # NOTE: country <> '' is the closest we can (performantly) get to rails'
      # String#blank? in SQL
      connection.execute 'TRUNCATE TABLE country_petition_journals'
      connection.execute <<-SQL.strip_heredoc
        INSERT INTO country_petition_journals
          (petition_id, country, signature_count, created_at, updated_at)
        SELECT
          petition_id, country, COUNT(*) AS signature_count,
          timezone('utc', now()), timezone('utc', now())
        FROM signatures
        WHERE state = 'validated'
        AND country <> ''
        GROUP BY petition_id, country
      SQL
    end

    private

    def unrecordable?(signature)
      signature.nil? || signature.petition.nil? || signature.country.blank? || !signature.validated?
    end
  end
end
