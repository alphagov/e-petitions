module Staged
  module PetitionCreator
    class ReplayPetition < Staged::Base::Petition
      include Staged::PetitionCreator::HasCreatorSignature

      class CreatorSignature < Staged::Base::CreatorSignature
      end
    end
  end
end
