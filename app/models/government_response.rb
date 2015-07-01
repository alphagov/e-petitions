class GovernmentResponse < ActiveRecord::Base
  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :summary, presence: true, length: { maximum: 500 }
  validates :details, length: { maximum: 4000 }, allow_blank: true

  after_create do
    petition.touch(:government_response_at)
  end
end
