module Staged
  module Validations
    module Email
      extend ActiveSupport::Concern

      included do
        validates :email,
          presence: { message: "Email must be completed" },
          format: {
            with: EMAIL_REGEX,
            unless: -> (e) { e.email.blank? },
            message: "Email '%{value}' not recognised."
          }
      end
    end
  end
end
