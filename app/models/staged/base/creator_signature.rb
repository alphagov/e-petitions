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
               :location_code, :constituency, to: :creator

      def validation_context
        :create
      end

      private

      attr_reader :petition

      def creator
        if petition.creator.nil?
          petition.build_creator(location_code: 'GB')
        end
        petition.creator
      end
    end
  end
end
