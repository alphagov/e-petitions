module Staged
  module Base
    class Signature
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      attr_reader :signature

      delegate :id, :to_param, :model_name, :to_key, :new_record?,
               :name, :email, :email?, :uk_citizenship, :postcode,
               :country, :petition_id, to: :signature

      def initialize(signature)
        @signature = signature
      end

      def validation_context
        :create
      end
    end
  end
end
