module Staged
  module Validations
    module SignerDetails
      extend ActiveSupport::Concern

      POSTCODE_REGEX = /\A(([A-Z]{1,2}[0-9][0-9A-Z]?[0-9][A-BD-HJLNP-UW-Z]{2})|(BFPO?(C\/O)?[0-9]{1,4})|(GIR0AA))\Z/i

      included do
        validates :name, presence: true, length: { maximum: 255 }
        validates :country, presence: true
        validates :postcode, presence: true, format: { with: POSTCODE_REGEX }, if: :united_kingdom?
        validates :uk_citizenship, acceptance: true, unless: :persisted?, allow_nil: false
      end

      def united_kingdom?
        country == 'United Kingdom'
      end
    end
  end
end
