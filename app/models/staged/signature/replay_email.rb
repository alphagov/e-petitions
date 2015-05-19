module Staged
  module Signature
    class ReplayEmail < Staged::Base::Signature
      include Staged::Validations::Email
    end
  end
end
