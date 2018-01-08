class Survey < ActiveRecord::Base
  has_and_belongs_to_many :petitions
  belongs_to :constituency, primary_key: :external_id

  validates :subject, presence: true
  validates :body, presence: true
  validates :percentage_petitioners, presence: true
  validates :constituency_id, length: { maximum: 255 }
  validates :petitions, presence: true
end
