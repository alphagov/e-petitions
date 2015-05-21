module Staged
  module PetitionSigner
    class ReplayEmail < Staged::Base::Signature
      include Staged::Validations::Email
      include Staged::Validations::MultipleSigners
    end
  end
end
