module Staged
  module PetitionSigner
    def self.manage(params, petition, stage, move)
      Manager.new(params, petition, stage, move, self::Stages)
    end

    def self.stages
      self::Stages.stage_names
    end

    class Manager
      def initialize(params, petition, stage, move, stages)
        @params = params
        @petition = petition
        @previous_stage = stage
        @move = move
        @stages = stages
      end

      # This is the stage we came from - the UI elements we showed the user
      # that generated these params
      attr_reader :previous_stage
      attr_reader :move
      attr_reader :stages

      def signature
        @_signature ||= build_signature
      end

      def stage
        stage_manager.result_stage.name
      end

      def stage_object
        stage_manager.result_stage.stage_object
      end

      def create_signature
        sanitize!
        stage_manager.create
      end

      private

      def stage_manager
        @_stage_manager ||= Staged::StageManager.new(stages, previous_stage, move, signature)
      end

      def sanitize!
        signature.email.strip! unless signature.email.blank?
      end

      def build_signature
        @petition.signatures.build(@params)
      end
    end
  end
end
