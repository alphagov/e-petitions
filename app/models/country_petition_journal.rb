class CountryPetitionJournal < ActiveRecord::Base
  belongs_to :petition

  validates :petition, presence: true
  validates :country, presence: true, length: { maximum: 255 }
  validates :country, uniqueness: { scope: [:petition_id] }
  validates :signature_count, presence: true

  alias_attribute :name, :country

  def self.for(petition, country)
    find_or_initialize_by(petition: petition, country: country)
  end

  def self.record_new_signature_for(signature)
    return if signature.nil? || signature.petition.nil? || signature.country.blank? || !signature.validated?
    self.for(signature.petition, signature.country).record_new_signature
  end

  def record_new_signature(at = Time.current)
    if self.new_record?
      update_attributes(signature_count: 1)
    else
      signature_count_field = self.class.connection.quote_column_name('signature_count')
      changes = "#{signature_count_field} = #{signature_count_field} + 1, updated_at = :updated_at"
      self.class.unscoped.where(id: id).update_all([changes, updated_at: at])
      # NOTE: even though we don't assume +1 is ok for the SQL update, we
      # want to avoid an extra SQL select from .reload so +1 is ok here
      raw_write_attribute(:signature_count, signature_count+1)
    end
  end

  def self.reset!
    connection.execute 'TRUNCATE TABLE country_petition_journals'
    connection.execute <<-SQL.strip_heredoc
      INSERT INTO country_petition_journals
        (petition_id, country, signature_count, created_at, updated_at)
      SELECT
        petition_id, country, COUNT(*) AS signature_count,
        timezone('utc', now()), timezone('utc', now())
      FROM signatures
      WHERE state = 'validated'
      GROUP BY petition_id, country
    SQL
  end
end
