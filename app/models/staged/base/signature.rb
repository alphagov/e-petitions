module Staged
  module Base
    class Signature
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      def initialize(signature)
        @signature = signature
      end
      delegate :id, :to_param, :model_name, :to_key, :new_record?,
               :name, :email, :encrypted_email, :uk_citizenship,
               :postcode, :country, :petition_id,
               to: :signature

      def validation_context
        :create
      end

      attr_reader :signature

      private

    end
  end
end
