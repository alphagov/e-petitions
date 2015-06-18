module Staged
  module Validations
    module PetitionDetails
      extend ActiveSupport::Concern

      included do
        validates :title,
          presence: { message: 'Action must be completed.' },
          length: { maximum: 80, unless: ->(pd) { pd.title.blank? }, message: 'Action is too long.' }
        validates :action,
          presence: { message: 'Background must be completed.' },
          length: { maximum: 300, unless: ->(pd) { pd.action.blank? }, message: 'Background is too long.' }
        validates :additional_details,
          length: { maximum: 800, unless: ->(pd) { pd.additional_details.blank? }, message: 'Additional details is too long.' }
      end
    end
  end
end
