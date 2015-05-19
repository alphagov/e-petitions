module Staged
  class PetitionCreator
    def initialize(params, request, stage, move)
      @params = params
      @request = request
      @previous_stage = stage
      @move = move
    end

    # This is the stage we came from - the UI elements we showed the user
    # that generated these params
    attr_reader :previous_stage
    attr_reader :move

    def petition
      @_petition ||= build_petition
    end

    def starting_stage
      @_starting_stage ||= Stages.for_name(previous_stage).new(petition)
    end

    def result_stage
      @_result_stage ||= starting_stage.go(move)
    end

    def reset_result_stage
      @_result_stage = Stages.find_earliest_error(petition)
    end

    def stage
      result_stage.name
    end

    def stage_object
      result_stage.stage_object
    end

    def create_petition
      sanitize!
      if result_stage.complete?
        if petition.save
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
        ['petition', 'creator', 'sponsors', 'replay-petition', 'replay-email', 'done']
      end

      def self.for_name(name)
        case name
        when 'petition'
          Stages::Petition
        when 'creator'
          Stages::Creator
        when 'sponsors'
          Stages::Sponsors
        when 'replay-petition'
          Stages::ReplayPetition
        when 'replay-email'
          Stages::ReplayEmail
        when 'done'
          Stages::Done
        else
          Stages::Petition
        end
      end

      def self.find_earliest_error(petition)
        stage = for_name('petition').new(petition)
        while stage.valid? && !stage.complete?
          stage = stage.go('next')
        end
        stage
      end

      class Stage < Struct.new(:petition)
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

      class Petition < Stages::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::Petition.new(petition)
        end

        def name; 'petition'; end
        def go_back; self; end
        def go_next; Stages.for_name('creator').new(petition); end
      end

      class Creator < Stages::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::Creator.new(petition)
        end

        def name; 'creator'; end
        def go_back; Stages.for_name('petition').new(petition); end
        def go_next; Stages.for_name('sponsors').new(petition); end
      end

      class Sponsors < Stages::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::Sponsors.new(petition)
        end

        def name; 'sponsors'; end
        def go_back; Stages.for_name('creator').new(petition); end
        def go_next; Stages.for_name('replay-petition').new(petition); end
      end

      class ReplayPetition < Stages::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::ReplayPetition.new(petition)
        end

        def name; 'replay-petition'; end
        def go_back; Stages.for_name('sponsors').new(petition); end
        def go_next; Stages.for_name('replay-email').new(petition); end
      end

      class ReplayEmail < Stages::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::ReplayEmail.new(petition)
        end

        def name; 'replay-email'; end
        def go_back; Stages.for_name('replay-petition').new(petition); end
        def go_next; Stages.for_name('done').new(petition); end
      end

      class Done < Stages::Stage
        def stage_object
          petition
        end

        def name; 'done'; end
        def go_back; self; end
        def go_next; self; end
        def complete?; true; end
      end
    end

    private

    def sanitize!
      if petition.creator_signature
        petition.creator_signature.email.strip! unless petition.creator_signature.email.blank?
        petition.creator_signature.ip_address = @request.remote_ip
      end
      petition.title.strip! unless petition.title.blank?
    end

    def build_petition
      ::Petition.new(@params)
    end
  end
end
