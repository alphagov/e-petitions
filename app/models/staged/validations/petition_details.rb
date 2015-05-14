module Staged
  module Validations
    module PetitionDetails
      extend ActiveSupport::Concern

      included do
        validates :title,
          presence: { message: 'Title must be completed.' },
          length: { maximum: 150, unless: ->(pd) { pd.title.blank? }, message: 'Title is too long.' }
        validates :action,
          presence: { message: 'Action must be completed.' },
          length: { maximum: 200, unless: ->(pd) { pd.action.blank? }, message: 'Action is too long.' }
        validates :description,
          presence: { message: 'Description must be completed.' },
          length: { maximum: 1000, unless: ->(pd) { pd.description.blank? }, message: 'Description is too long.' }
        validates :duration, presence: { message: 'Duration must be completed.' }
      end
    end
  end
end
