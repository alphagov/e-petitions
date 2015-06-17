class EmailRequestedReceipt < ActiveRecord::Base
  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :petition_id, uniqueness: true
end
