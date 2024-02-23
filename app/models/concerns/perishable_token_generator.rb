module PerishableTokenGenerator
  extend ActiveSupport::Concern

  class_methods do
    def has_perishable_token(called: 'perishable_token')
      before_create do
        write_attribute(called, SecureRandom.base58(20))
      end
    end
  end
end
