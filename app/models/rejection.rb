class Rejection < ActiveRecord::Base
  include Translatable

  translate :details

  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :code, presence: true, inclusion: { in: :rejection_codes }
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

  class << self
    def used?(code)
      where(code: code).any?
    end
  end

  def rejected_at
    @rejected_at || Time.current
  end

  def hide_petition?
    code.in?(hidden_codes)
  end

  def state_for_petition
    hide_petition? ? Petition::HIDDEN_STATE : Petition::REJECTED_STATE
  end

  private

  def rejection_codes
    @rejection_codes ||= RejectionReason.codes
  end

  def hidden_codes
    @hidden_codes ||= RejectionReason.hidden_codes
  end
end
