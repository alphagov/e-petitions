module Staged
  class StageManager < Struct.new(:stages, :previous_stage, :move, :model)
    delegate :for_name, :initial_stage,
             to: :stages

    def starting_stage
      @_starting_stage ||= for_name(previous_stage).new(model)
    end

    def result_stage
      @_result_stage ||= starting_stage.go(move)
    end

    def reset_result_stage
      @_result_stage = find_earliest_error
    end

    def create
      if result_stage.complete?
        if model.save
          true
        else
          reset_result_stage
          false
        end
      else
        false
      end
    end

    private

    def find_earliest_error
      stage = initial_stage.new(model)
      while stage.valid? && !stage.complete?
        stage = stage.go('next')
      end
      stage
    end

  end
end
