module Staged
  module Signature
    class ReplayEmail < Staged::Base::Signature
      include Staged::Validations::Email
      include Staged::Validations::MultipleSigners
    end
  end
end
