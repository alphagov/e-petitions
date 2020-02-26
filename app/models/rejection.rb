class Rejection < ActiveRecord::Base
  include Translatable

  CODES = %w[insufficient duplicate irrelevant no-action fake-name libellous offensive bad-address not-suitable]
  HIDDEN_CODES = %w[libellous offensive not-suitable]

  translate :details

  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :code, presence: true, inclusion: { in: CODES }
  validates :details_en, :details_cy, length: { maximum: 4000 }, allow_blank: true

  attr_writer :rejected_at

  after_save do
    # Prevent deprecation warnings about the
    # upcoming new behaviour of attribute_changed?
    petition.reload

    if petition.rejected_at?
      petition.update!(state: state_for_petition)
    else
      petition.update!(state: state_for_petition, rejected_at: rejected_at)
    end
  end

  def rejected_at
    @rejected_at || Time.current
  end

  def hide_petition?
    code.in?(HIDDEN_CODES)
  end

  def state_for_petition
    hide_petition? ? Petition::HIDDEN_STATE : Petition::REJECTED_STATE
  end
end
