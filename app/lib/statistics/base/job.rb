module Statistics
  module Base
    class Job < ApplicationJob
      class_attribute :report_class, instance_writer: false, default: Base::Report

      queue_as :low_priority

      rescue_from StandardError do |exception|
        Appsignal.send_exception exception
        StatisticsMailer.error(arguments.first).deliver_now
      end

      def perform(user)
        raise RuntimeError, "The statistics report job subclass '#{self.class.name}' is missing an implementation for the #perform method."
      end

      private

      def report
        @report ||= report_class.new(*report_arguments)
      end

      def report_arguments
        arguments[1..-1]
      end

      def production?
        Rails.env.production?
      end
    end
  end
end
