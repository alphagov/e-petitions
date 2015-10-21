module Staged
  module Base
    class CreatorSignature
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      def initialize(petition)
        @petition = petition
      end

      delegate :id, :to_param, :model_name, :to_key, :name,
               :email, :email?, :uk_citizenship, :postcode,
               :country, :constituency, to: :creator_signature

      def validation_context
        :create
      end

      private

      attr_reader :petition

      def creator_signature
        if petition.creator_signature.nil?
          petition.build_creator_signature(country: 'United Kingdom')
        end
        petition.creator_signature
      end
    end
  end
end
