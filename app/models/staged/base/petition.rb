module Staged
  module Base
    class Petition
      include ActiveModel::Model
      include ActiveModel::Validations::Callbacks

      attr_reader :petition
      def initialize(petition)
        @petition = petition
      end

      delegate :id, :to_param, :model_name, :to_key,
               :action, :background, :additional_details,
               :duration, :creator_signature, to: :petition
    end
  end
end
