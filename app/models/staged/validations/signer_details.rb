module Staged
  module Validations
    module SignerDetails
      extend ActiveSupport::Concern

      included do
        validates :name,
          presence: { message: 'Name must be completed.' },
          length: { maximum: 255 }

        with_options on: :create do |creator|
          creator.validates :email,
            presence: { message: 'Email must be completed.' },
            confirmation: { message: 'Email should match confirmation.' }

          creator.validates :email_confirmation, presence: { message: 'Email confirmation must be completed.' }
        end

        validates :country, presence: { message: 'Country must be completed.' }

        validates :postcode,
          presence: { message: 'Postcode must be completed.' },
          format: {
            with: /\A(([A-Z]{1,2}[0-9][0-9A-Z]? ?[0-9][A-BD-HJLNP-UW-Z]{2})|(BFPO? ?(C\/O)? ?[0-9]{1,4})|(GIR 0AA))\Z/i,
            message: 'Postcode not recognised.'
          },
          if: ->(cd) { cd.country == 'United Kingdom' }

        with_options unless: :persisted? do |creator|
          creator.validates :uk_citizenship,
            acceptance: { allow_nil: false, message: 'You must be a British citizen or normally live in the UK to create or sign petitions.' }
        end
      end
    end
  end
end
