class Rejection < ActiveRecord::Base
  CODES = %w[no-action duplicate libellous offensive irrelevant honours fake-name]
  HIDDEN_CODES = %w[libellous offensive]

  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :code, presence: true, inclusion: { in: CODES }
  validates :details, length: { maximum: 4000 }, allow_blank: true

  after_create do
    petition.update!(state: state_for_petition, rejected_at: Time.current)
  end

  def hide_petition?
    code.in?(HIDDEN_CODES)
  end

  def state_for_petition
    hide_petition? ? Petition::HIDDEN_STATE : Petition::REJECTED_STATE
  end
end
