class GovernmentResponse < ActiveRecord::Base
  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :summary, presence: true, length: { maximum: 200 }
  validates :details, length: { maximum: 6000 }, allow_blank: true
  validates :responded_on, presence: true

  after_create do
    petition.touch(:government_response_at) unless petition.government_response_at?
  end

  def responded_on
    super || default_responded_on
  end

  private

  def default_responded_on
    if petition && petition.government_response_at
      petition.government_response_at.to_date
    elsif created_at
      created_at.to_date
    elsif new_record?
      Date.current
    end
  end
end
