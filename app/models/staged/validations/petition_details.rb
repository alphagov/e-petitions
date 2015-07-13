module Staged
  module Validations
    module PetitionDetails
      extend ActiveSupport::Concern

      included do
        validates :action, presence: true, length: { maximum: 80, allow_blank: true }
        validates :background, presence: true, length: { maximum: 300, allow_blank: true }
        validates :additional_details, length: { maximum: 800, allow_blank: true }
      end
    end
  end
end
