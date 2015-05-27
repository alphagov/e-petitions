module Staged
  module PetitionSponsor
    def self.manage(params, sponsor, petition, stage, move)
      Manager.new(params, sponsor, petition, stage, move, Staged::PetitionSigner::Stages)
    end

    def self.stages
      Staged::PetitionSigner::Stages.stage_names
    end

    class Manager < Staged::PetitionSigner::Manager
      def initialize(params, sponsor, petition, stage, move, stages)
        super(params, petition, stage, move, stages)
        @sponsor = sponsor
      end

      private

      def build_signature
        @sponsor.build_signature(@params)
      end
    end
  end
end
