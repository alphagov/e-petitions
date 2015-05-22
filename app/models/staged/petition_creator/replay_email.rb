module Staged
  module PetitionCreator
    class ReplayEmail < Staged::Base::Petition
      include Staged::PetitionCreator::HasCreatorSignature

      class CreatorSignature < Staged::Base::CreatorSignature
        include Staged::Validations::Email
      end
    end
  end
end
