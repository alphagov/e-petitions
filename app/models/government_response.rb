class GovernmentResponse < ApplicationRecord
  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :summary, presence: true, length: { maximum: 200 }
  validates :details, length: { maximum: 6000 }, allow_blank: true

  after_create do
    petition.touch(:government_response_at)
  end
end
