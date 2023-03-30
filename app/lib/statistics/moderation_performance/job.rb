module Statistics
  module ModerationPerformance
    class Job < Base::Job
      self.report_class = ModerationPerformance::Report

      def perform(user, scope, parliament_id, period)
        report.validate!

        StatisticsMailer.moderation_performance(user, report).deliver_now
      end
    end
  end
end
