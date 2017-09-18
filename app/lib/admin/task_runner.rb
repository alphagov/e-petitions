module Admin
  class TaskRunner
    TASKS = {
      "backfill_constituencies" => lambda { |params|
        case params[:since]
        when "week"
          since = 1.week.ago
        when "month"
          since = 1.month.ago
        when "three_months"
          since = 3.months.ago
        else
          since = nil
        end

        BackfillConstituenciesJob.perform_later(since: since.try(:iso8601))
      }
    }

    attr_reader :params

    class << self
      def run(params)
        new(params).run.any?
      rescue StandardError => e
        Appsignal.send_exception(e)
        return false
      end
    end

    def initialize(params)
      @params = params
    end

    def run
      tasks.each { |task| run_task(task) }
    end

    private

    def run_task(task)
      TASKS[task].call(params[task])
    end

    def tasks
      Array(params[:tasks]).select { |t| TASKS.key?(t) }
    end
  end
end
