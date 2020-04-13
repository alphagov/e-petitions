class Rejection < ActiveRecord::Base
  include Translatable

  translate :details

  belongs_to :petition, touch: true
  belongs_to :rejection_reason, foreign_key: :code, primary_key: :code

  validates :petition, presence: true
  validates :code, presence: true, inclusion: { in: :rejection_codes }
  validates :details_en, :details_cy, length: { maximum: 4000 }, allow_blank: true

  attr_writer :rejected_at

  delegate :description_en, :description_cy, to: :rejection_reason

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

  def content
    translated_method(:content_en, :content_cy)
  end

  def content_en
    [description_en, details_en].reject(&:blank?).join("\n\n")
  end

  def content_cy
    [description_cy, details_cy].reject(&:blank?).join("\n\n")
  end

  def description
    translated_method(:description_en, :description_cy)
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
