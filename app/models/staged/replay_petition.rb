module Staged
  class ReplayPetition < Staged::Base::Petition
    include Staged::HasCreatorSignature

    class CreatorSignature < Staged::Base::CreatorSignature
    end
  end
end
