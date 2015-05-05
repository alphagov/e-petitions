module PerishableTokenGenerator

  extend ActiveSupport::Concern
  
  included do
    before_create :set_perishable_token
    
    private
    def set_perishable_token
      self.perishable_token = Authlogic::Random.friendly_token
    end
    
  end
end
