module Staged
  module Petition
    class Creator < Staged::Base::Petition
      include Staged::Petition::HasCreatorSignature

      class CreatorSignature < Staged::Base::CreatorSignature
        include Staged::Validations::SignerDetails
        include Staged::Validations::Email
      end
    end
  end
end

