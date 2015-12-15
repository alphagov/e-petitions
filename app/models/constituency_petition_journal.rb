class ConstituencyPetitionJournal < ActiveRecord::Base
  belongs_to :petition
  belongs_to :constituency, primary_key: :external_id

  validates :petition, presence: true
  validates :constituency_id, presence: true, length: { maximum: 255 }
  validates :constituency_id, uniqueness: { scope: [:petition_id] }
  validates :signature_count, presence: true

  delegate :name, :ons_code, :mp_name, to: :constituency

  scope :ordered, -> {
    order("#{table_name}.signature_count DESC")
  }
  scope :with_signatures_for, ->(constituency_id) {
    where("#{table_name}.signature_count > 0").
    where(table_name => { constituency_id: constituency_id})
  }

  def self.for(petition, constituency_id)
    find_or_initialize_by(petition: petition, constituency_id: constituency_id)
  end

  def self.record_new_signature_for(signature)
    return if signature.nil? || signature.petition.nil? || signature.constituency_id.blank? || !signature.validated?
    self.for(signature.petition, signature.constituency_id).record_new_signature
  end

  def record_new_signature(at = Time.current)
    if self.new_record?
      begin
        update_attributes(signature_count: 0)
      rescue ActiveRecord::RecordNotUnique => e
        # Another thread or process beat us to it
      end
    end

    signature_count_field = self.class.connection.quote_column_name('signature_count')
    changes = "#{signature_count_field} = #{signature_count_field} + 1, updated_at = :updated_at"
    self.class.unscoped.where(id: id).update_all([changes, updated_at: at])
    # NOTE: even though we don't assume +1 is ok for the SQL update, we
    # want to avoid an extra SQL select from .reload so +1 is ok here
    raw_write_attribute(:signature_count, signature_count+1)
  end

  def self.reset!
    connection.execute "TRUNCATE TABLE #{self.table_name}"
    connection.execute <<-SQL.strip_heredoc
      INSERT INTO #{self.table_name}
        (petition_id, constituency_id, signature_count, created_at, updated_at)
      SELECT
        petition_id, constituency_id, COUNT(*) AS signature_count,
        timezone('utc', now()), timezone('utc', now())
      FROM signatures
      WHERE state = 'validated'
      GROUP BY petition_id, constituency_id
    SQL
  end

end
