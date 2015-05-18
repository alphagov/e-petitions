module Staged
  class Creator < Staged::Base::Petition
    include ActiveModel::Model
    include Staged::HasCreatorSignature

    class CreatorSignature < Staged::Base::CreatorSignature
      include Staged::Validations::SignerDetails
      include Staged::Validations::Email
    end
  end
end

