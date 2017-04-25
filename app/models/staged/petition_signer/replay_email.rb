module Staged
  module PetitionSigner
    class ReplayEmail < Staged::Base::Signature
      include Staged::Validations::Email
    end
  end
end
