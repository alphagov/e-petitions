module Staged
  module Validations
    module Email
      extend ActiveSupport::Concern

      included do
        validates :email, presence: true, format: { with: EMAIL_REGEX, allow_blank: true }
      end
    end
  end
end
