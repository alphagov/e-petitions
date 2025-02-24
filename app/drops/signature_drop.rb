class SignatureDrop < ApplicationDrop
  def initialize(signature)
    @signature = signature
  end

  with_options to: :@signature do
    delegate :name, :creator, :sponsor
  end

  def unsubscribe_url
    routes.unsubscribe_signature_url(@signature, token: @signature.perishable_token)
  end

  def verification_url
    routes.verify_signature_url(@signature, token: @signature.perishable_token)
  end
end
