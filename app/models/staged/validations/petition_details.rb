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
        validates :description,
          length: { maximum: 800, unless: ->(pd) { pd.description.blank? }, message: 'Supporting details is too long.' }
      end
    end
  end
end
