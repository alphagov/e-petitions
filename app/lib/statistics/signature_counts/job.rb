module Statistics
  module SignatureCounts
    class Job < Base::Job
      self.report_class = SignatureCounts::Report

      def perform(user, scope, parliament_id, breakdown, start, finish)
        report.validate!

        StatisticsMailer.signature_counts(user, report).deliver_now
      end
    end
  end
end
