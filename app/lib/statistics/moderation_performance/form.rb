module Statistics
  module ModerationPerformance
    class Form < Base::Form
      self.job_class = ModerationPerformance::Job

      attribute :scope, :string, default: "current"
      attribute :parliament_id, :integer
      attribute :period, :string, default: "week"

      validates :scope, presence: true, inclusion: { in: %w[current archived] }
      validates :parliament_id, inclusion: { in: :parliament_ids }, allow_blank: true
      validates :period, presence: true, inclusion: { in: %w[week month] }

      def parliaments
        @parliaments ||= Parliament.archived.map { |p| [p.name, p.id] }
      end

      private

      def job_arguments
        [scope, parliament_id, period]
      end

      def parliament_ids
        parliaments.map(&:last)
      end
    end
  end
end
