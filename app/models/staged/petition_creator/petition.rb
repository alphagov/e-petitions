module Staged
  module PetitionCreator
    class Petition < Staged::Base::Petition
      include Staged::Validations::PetitionDetails
    end
  end
end
