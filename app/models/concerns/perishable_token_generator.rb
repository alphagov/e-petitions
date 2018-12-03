module PerishableTokenGenerator
  extend ActiveSupport::Concern

  class_methods do
    def has_perishable_token(called: 'perishable_token')
      before_create do
        write_attribute(called, Authlogic::Random.friendly_token)
      end
    end
  end
end
