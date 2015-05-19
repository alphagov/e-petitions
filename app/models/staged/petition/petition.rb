module Staged
  module Petition
    class Petition < Staged::Base::Petition
      include Staged::Validations::PetitionDetails
    end
  end
end
