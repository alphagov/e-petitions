module Statistics
  module SignatureCounts
    class Form < Base::Form
      self.job_class = SignatureCounts::Job

      attribute :scope, :string, default: "current"
      attribute :parliament_id, :integer
      attribute :breakdown, :string, default: "none"
      attribute :start, :date
      attribute :finish, :date

      validates :scope, presence: true, inclusion: { in: %w[current archived] }
      validates :parliament_id, inclusion: { in: :parliament_ids }, allow_blank: true
      validates :breakdown, presence: true, inclusion: { in: %w[none country region constituency] }
      validates :start, date: true
      validates :finish, date: true

      validate :start_is_in_the_past
      validate :start_is_within_parliament
      validate :finish_is_in_the_past
      validate :finish_is_after_start

      def parliaments
        @parliaments ||= Parliament.archived.map { |p| [p.name, p.id] }
      end

      private

      def parliament_id?
        parliament_id.present?
      end

      def parliament
        if parliament_id? && Parliament.exists?(parliament_id)
          @parliament ||= Parliament.find(parliament_id)
        end
      end

      def start?
        start.present?
      end

      def finish?
        finish.present?
      end

      def date_range?
        start? && finish?
      end

      def start_is_in_the_past
        if start? && start.after?(Date.current)
          errors.add(:start, :before)
        end
      end

      def start_is_within_parliament
        if start? && parliament
          unless parliament.sitting?(start.at_end_of_day)
            errors.add(:start, :within)
          end
        end
      end

      def finish_is_after_start
        if date_range? && start.after?(finish)
          errors.add(:start, :invalid)
        end
      end

      def finish_is_in_the_past
        if finish? && finish.after?(Date.current)
          errors.add(:finish, :before)
        end
      end

      def job_arguments
        [scope, parliament_id, breakdown, start, finish]
      end

      def parliament_ids
        parliaments.map(&:last)
      end
    end
  end
end
