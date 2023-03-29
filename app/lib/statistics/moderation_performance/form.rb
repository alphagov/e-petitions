module Statistics
  module ModerationPerformance
    class Form < Base::Form
      self.job_class = ModerationPerformance::Job

      attribute :parliament_id, :integer
      attribute :period, :string

      validates :parliament_id, inclusion: { in: :parliament_ids }
      validates :period, presence: true, inclusion: { in: %w[week month] }

      def parliaments
        current_parliament + archived_parliaments
      end

      private

      def job_arguments
        [parliament_id, period]
      end

      def parliament_ids
        parliaments.map(&:last)
      end

      def current_parliament
        [["Current Parliament", nil]]
      end

      def archived_parliaments
        @archived_parliaments ||= Parliament.archived.map { |p| [p.name, p.id] }
      end
    end
  end
end
