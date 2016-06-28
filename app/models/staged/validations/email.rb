module Staged
  module Validations
    module Email
      extend ActiveSupport::Concern

      included do
        validates :email, presence: true, email: { allow_blank: true }
      end
    end
  end
end
