module Staged
  module Petition
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

      class Petition < Staged::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::Petition.new(model)
        end

        def name; 'petition'; end
        def go_back; self; end
        def go_next; Stages.for_name('creator').new(model); end
      end

      class Creator < Staged::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::Creator.new(model)
        end

        def name; 'creator'; end
        def go_back; Stages.for_name('petition').new(model); end
        def go_next; Stages.for_name('sponsors').new(model); end
      end

      class Sponsors < Staged::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::Sponsors.new(model)
        end

        def name; 'sponsors'; end
        def go_back; Stages.for_name('creator').new(model); end
        def go_next; Stages.for_name('replay-petition').new(model); end
      end

      class ReplayPetition < Staged::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::ReplayPetition.new(model)
        end

        def name; 'replay-petition'; end
        def go_back; Stages.for_name('sponsors').new(model); end
        def go_next; Stages.for_name('replay-email').new(model); end
      end

      class ReplayEmail < Staged::Stage
        def stage_object
          @_stage_object ||= Staged::Petition::ReplayEmail.new(model)
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
