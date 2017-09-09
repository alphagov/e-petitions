module Staged
  module PetitionCreator
    module HasCreatorSignature
      extend ActiveSupport::Concern

      included do
        validate :creator_valid?

        def creator
          @_creator ||= self.class::CreatorSignature.new(petition)
        end

        private

        def creator_valid?
          if creator.valid?
            true
          else
            creator.errors.each do |attribute, message|
              attribute = "creator.#{attribute}"
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
