module Staged
  module Petition
    class ReplayPetition < Staged::Base::Petition
      include Staged::Petition::HasCreatorSignature

      class CreatorSignature < Staged::Base::CreatorSignature
      end
    end
  end
end
