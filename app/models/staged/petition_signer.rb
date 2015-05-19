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

    def starting_stage
      @_starting_stage ||= Stages.for_name(previous_stage).new(signature)
    end

    def result_stage
      @_result_stage ||= starting_stage.go(move)
    end

    def reset_result_stage
      @_result_stage = Stages.find_earliest_error(signature)
    end

    def stage
      result_stage.name
    end

    def stage_object
      result_stage.stage_object
    end

    def create_signature
      sanitize!
      if result_stage.complete?
        if signature.save
          true
        else
          reset_result_stage
          false
        end
      else
        false
      end
    end

    def self.stages
      Stages.names
    end

    module Stages
      def self.names
        ['signer', 'replay-email', 'done']
      end

      def self.for_name(name)
        case name
        when 'signer'
          Stages::Signer
        when 'replay-email'
          Stages::ReplayEmail
        when 'done'
          Stages::Done
        else
          Stages::Signer
        end
      end

      def self.find_earliest_error(signature)
        stage = for_name('signer').new(signature)
        while stage.valid? && !stage.complete?
          stage = stage.go('next')
        end
        stage
      end

      class Stage < Struct.new(:signature)
        def complete?; false; end

        def go(move)
          case move
          when 'back'
            go_back
          when 'next'
            if valid?
              go_next
            else
              stay
            end
          else
            stay
          end
        end

        def stay; self; end

        def valid?
          stage_object.valid?
        end
      end

      class Signer < Stages::Stage
        def stage_object
          @_stage_object ||= Staged::Signature::Signer.new(signature)
        end

        def name; 'signer'; end
        def go_back; self; end
        def go_next; Stages.for_name('replay-email').new(signature); end
      end

      class ReplayEmail < Stages::Stage
        def stage_object
          @_stage_object ||= Staged::Signature::ReplayEmail.new(signature)
        end

        def name; 'replay-email'; end
        def go_back; Stages.for_name('signer').new(signature); end
        def go_next; Stages.for_name('done').new(signature); end
      end

      class Done < Stages::Stage
        def stage_object
          signature
        end

        def name; 'done'; end
        def go_back; self; end
        def go_next; self; end
        def complete?; true; end
      end
    end

    private

    def sanitize!
      signature.email.strip! unless signature.email.blank?
    end

    def build_signature
      @petition.signatures.build(@params)
    end
  end
end
