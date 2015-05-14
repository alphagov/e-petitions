module Staged
  class Submit < Staged::Base::Petition
    include Staged::HasCreatorSignature

    class CreatorSignature < Staged::Base::CreatorSignature
      include Staged::Validations::Terms
    end
  end
end
