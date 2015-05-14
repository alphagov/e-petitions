module Staged
  class Petition < Staged::Base::Petition
    include Staged::Validations::PetitionDetails
  end
end
