module Staged
  module Petition
    module HasCreatorSignature
      extend ActiveSupport::Concern

      included do
        def valid?
          super && creator_signature_valid?
        end

        def creator_signature
          @_creator_signature ||= self.class::CreatorSignature.new(petition)
        end

        def creator_signature_valid?
          if creator_signature.valid?
            true
          else
            creator_signature.errors.each do |attribute, message|
              attribute = "creator_signature.#{attribute}"
              errors[attribute] << message
              errors[attribute].uniq!
            end
            false
          end
        end
      end
    end
  end
end
