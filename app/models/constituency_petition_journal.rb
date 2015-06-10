class ConstituencyPetitionJournal < ActiveRecord::Base
  belongs_to :petition

  validates :petition, presence: true
  validates :constituency_id, presence: true, length: { maximum: 255 }
  validates :petition_id, uniqueness: { scope: [:constituency_id] }
  validates :signature_count, presence: true

  def self.for(petition, constituency_id)
    find_or_create_by(petition: petition, constituency_id: constituency_id)
  end

  def record_new_signature(at = Time.current)
    signature_count_field = self.class.connection.quote_column_name('signature_count')
    changes = "#{signature_count_field} = #{signature_count_field} + 1, updated_at = :updated_at"
    self.class.where(id: id).update_all([changes, updated_at: at])
    reload
  end
end
