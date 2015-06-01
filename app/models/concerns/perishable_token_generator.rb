module PerishableTokenGenerator

  extend ActiveSupport::Concern

  class_methods do
    def has_perishable_token(called: 'perishable_token')
      setter_method_name = :"set_#{called}"
      before_create setter_method_name

      define_method setter_method_name do
        self.send(:"#{called}=", Authlogic::Random.friendly_token)
      end
      private setter_method_name
    end
  end
end
