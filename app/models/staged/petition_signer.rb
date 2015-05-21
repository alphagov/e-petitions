module Staged
  class PetitionSigner
    def initialize(params, petition, stage, move)
      @params = params
      @petition = petition
      @previous_stage = stage
      @move = move
    end

    # This is the stage we came from - the UI elements we showed the user
    # that generated these params
    attr_reader :previous_stage
    attr_reader :move

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

    def self.stages
      stages_scenario.stage_names
    end

    private

    def self.stages_scenario
      Staged::Signature::Stages
    end

    def stage_manager
      @_stage_manager ||= Staged::StageManager.new(self.class.stages_scenario, previous_stage, move, signature)
    end

    def sanitize!
      signature.email.strip! unless signature.email.blank?
    end

    def build_signature
      @petition.signatures.build(@params)
    end
  end
end
