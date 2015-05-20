module Staged
  module Signature
    class Signer < Staged::Base::Signature
      include Staged::Validations::SignerDetails
      include Staged::Validations::Email
      include Staged::Validations::MultipleSigners
    end
  end
end
