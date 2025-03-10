module Archived
  class SignatureDrop < ApplicationDrop
    def initialize(signature)
      @signature = signature
    end

    with_options to: :@signature do
      delegate :name, :creator, :sponsor
    end

    def unsubscribe_url
      routes.unsubscribe_archived_signature_url(@signature, token: @signature.perishable_token)
    end
  end
end
