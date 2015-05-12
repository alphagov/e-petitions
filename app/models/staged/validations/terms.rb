module Staged
  module Validations
    module Terms
      extend ActiveSupport::Concern

      included do
        validates :terms_and_conditions,
          acceptance: {
            message: "You must accept the terms and conditions.",
            allow_nil: false
          },
          unless: :persisted?
      end
    end
  end
end

