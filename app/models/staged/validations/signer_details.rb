require 'postcode_validator'

module Staged
  module Validations
    module SignerDetails
      extend ActiveSupport::Concern

      included do
        validates :name, presence: true, length: { maximum: 255 }
        validates :location_code, presence: true
        validates :postcode, presence: true, postcode: true, if: :united_kingdom?
        validates :uk_citizenship, acceptance: true, unless: :persisted?, allow_nil: false
      end

      def united_kingdom?
        location_code == 'GB'
      end
    end
  end
end
