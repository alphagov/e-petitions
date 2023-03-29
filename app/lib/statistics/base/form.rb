module Statistics
  module Base
    class Form
      class << self
        def report_name
          @report_name ||= name.split(/::/).second
        end

        def report_key
          @report_key ||= report_name.underscore
        end

        def report_title
          @report_title ||= report_name.titleize
        end

        def report_human_name
          @report_human_name ||= report_name.humanize
        end

        def model_name
          @model_name ||= ActiveModel::Name.new(self, )
        end

        def build(params)
          new(params.fetch(:report, {}).permit(attribute_names))
        end
      end

      include ActiveModel::Model
      include ActiveModel::Attributes

      attr_reader :params

      class_attribute :job_class, instance_writer: false, default: Base::Job

      delegate :report_key, to: :class
      alias_method :tab, :report_key
      alias_method :to_partial_path, :report_key

      def save
        valid? && enqueue_job
      end

      private

      def enqueue_job
        job_class.perform_later(current_user, *job_arguments)
      end

      def job_arguments
        []
      end

      def current_user
        Admin::Current.user
      end
    end
  end
end
