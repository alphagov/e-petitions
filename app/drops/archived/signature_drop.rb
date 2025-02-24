module Archived
  class SignatureDrop < ApplicationDrop
    def initialize(signature)
      @signature = signature
    end

    with_options to: :@signature do
      delegate :name, :creator, :sponsor
    end
  end
end
