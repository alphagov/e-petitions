module Staged
  module Petition
    class ReplayEmail < Staged::Base::Petition
      include Staged::Petition::HasCreatorSignature

      class CreatorSignature < Staged::Base::CreatorSignature
        include Staged::Validations::Email
      end
    end
  end
end
