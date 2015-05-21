module Staged
  module PetitionCreator
    module Stages
      def self.stage_names
        ['petition', 'creator', 'sponsors', 'replay-petition', 'replay-email', 'done']
      end

      def self.initial_stage
        for_name('petition')
      end

      def self.for_name(name)
        case name
        when 'petition'
          self::Petition
        when 'creator'
          self::Creator
        when 'sponsors'
          self::Sponsors
        when 'replay-petition'
          self::ReplayPetition
        when 'replay-email'
          self::ReplayEmail
        when 'done'
          self::Done
        else
          self::Petition
        end
      end

      class Petition < Staged::Stage
        def stage_object
          @_stage_object ||= ::Staged::PetitionCreator::Petition.new(model)
        end

        def name; 'petition'; end
        def go_back; self; end
        def go_next; Stages.for_name('creator').new(model); end
      end

      class Creator < Staged::Stage
        def stage_object
          @_stage_object ||= ::Staged::PetitionCreator::Creator.new(model)
        end

        def name; 'creator'; end
        def go_back; Stages.for_name('petition').new(model); end
        def go_next; Stages.for_name('sponsors').new(model); end
      end

      class Sponsors < Staged::Stage
        def stage_object
          @_stage_object ||= ::Staged::PetitionCreator::Sponsors.new(model)
        end

        def name; 'sponsors'; end
        def go_back; Stages.for_name('creator').new(model); end
        def go_next; Stages.for_name('replay-petition').new(model); end
      end

      class ReplayPetition < Staged::Stage
        def stage_object
          @_stage_object ||= ::Staged::PetitionCreator::ReplayPetition.new(model)
        end

        def name; 'replay-petition'; end
        def go_back; Stages.for_name('sponsors').new(model); end
        def go_next; Stages.for_name('replay-email').new(model); end
      end

      class ReplayEmail < Staged::Stage
        def stage_object
          @_stage_object ||= ::Staged::PetitionCreator::ReplayEmail.new(model)
        end

        def name; 'replay-email'; end
        def go_back; Stages.for_name('replay-petition').new(model); end
        def go_next; Stages.for_name('done').new(model); end
      end

      class Done < Staged::Stage
        def stage_object; model; end
        def name; 'done'; end
        def go_back; self; end
        def go_next; self; end
        def complete?; true; end
      end
    end
  end
end
