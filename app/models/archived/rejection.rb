require_dependency 'archived'

module Archived
  class Rejection < ActiveRecord::Base
    CODES = %w[duplicate irrelevant no-action honours fake-name foi libellous offensive]
    HIDDEN_CODES = %w[libellous offensive]

    belongs_to :petition, touch: true

    validates :petition, presence: true
    validates :code, presence: true, inclusion: { in: CODES }
    validates :details, length: { maximum: 4000 }, allow_blank: true

    after_create do
      # Prevent deprecation warnings about the
      # upcoming new behaviour of attribute_changed?
      petition.reload

      if petition.rejected_at?
        petition.update!(state: state_for_petition)
      else
        petition.update!(state: state_for_petition, rejected_at: Time.current)
      end
    end

    def hide_petition?
      code.in?(HIDDEN_CODES)
    end

    def state_for_petition
      hide_petition? ? Petition::HIDDEN_STATE : Petition::REJECTED_STATE
    end
  end
end
