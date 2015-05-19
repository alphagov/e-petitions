module Staged
  module Base
    class Signature
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      def initialize(signature)
        @signature = signature
      end
      delegate :id, :to_param, :model_name, :to_key,
               :name, :email, :uk_citizenship,
               :postcode, :country,
               to: :signature

      def validation_context
        :create
      end

      attr_reader :signature

      private

    end
  end
end
