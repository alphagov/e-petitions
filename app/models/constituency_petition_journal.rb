class ConstituencyPetitionJournal < ActiveRecord::Base
  belongs_to :petition

  validates :petition, presence: true
  validates :constituency_id, presence: true, length: { maximum: 255 }
  validates :petition_id, uniqueness: { scope: [:constituency_id] }
  validates :signature_count, presence: true

  scope :ordered, -> {
    order("#{table_name}.signature_count DESC")
  }
  scope :with_signatures_for, ->(constituency_id) {
    where("#{table_name}.signature_count > 0").
    where(table_name => { constituency_id: constituency_id})
  }

  def self.for(petition, constituency_id)
    find_or_create_by(petition: petition, constituency_id: constituency_id)
  end

  def self.record_new_signature_for(signature)
    return if signature.nil? || signature.petition.nil? || signature.constituency_id.blank? || !signature.validated?
    self.for(signature.petition, signature.constituency_id).record_new_signature
  end

  def record_new_signature(at = Time.current)
    signature_count_field = self.class.connection.quote_column_name('signature_count')
    changes = "#{signature_count_field} = #{signature_count_field} + 1, updated_at = :updated_at"
    self.class.where(id: id).update_all([changes, updated_at: at])
    reload
  end
end
