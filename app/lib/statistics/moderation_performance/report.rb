module Statistics
  module ModerationPerformance
    class Report < Base::Report
      attr_reader :scope, :parliament_id, :period

      validates :scope, presence: true, inclusion: { in: %w[current archived] }
      validate :parliament_exists, if: :parliament_id?
      validates :period, presence: true, inclusion: { in: %w[week month] }

      def initialize(scope, parliament_id, period)
        @scope, @parliament_id, @period = scope, parliament_id, period
      end

      def filename
        if parliament
          "moderation-performance-#{parliament.period}-by-#{period}.csv"
        elsif scope == "archived"
          "moderation-performance-archived-by-#{period}.csv"
        else
          "moderation-performance-by-#{period}.csv"
        end
      end

      def content
        CSV.generate do |csv|
          csv << ['Period', 'Percentage moderated within 7 days']

          rows.each do |row|
            csv << row
          end
        end
      end

      private

      def sql
        <<~SQL
          SELECT
            TO_CHAR(#{date_trunc}, #{date_format}) AS period,
            ROUND(#{expression}, 1) AS percentage_within_target
          FROM
            #{table_name}
          WHERE
            #{conditions.join(' AND ')}
          GROUP BY
            #{date_trunc}
          ORDER BY
            #{date_trunc}
        SQL
      end

      def table_name
        scope == "current" ? "petitions" : "archived_petitions"
      end

      def date_trunc
        "DATE_TRUNC('#{period}', moderation_threshold_reached_at)"
      end

      def date_format
        case period
        when "week"
          "'DD Mon YYYY'"
        when "month"
          "'Mon YYYY'"
        else
          raise RuntimeError, "Unexpected date format: #{format}"
        end
      end

      def expression
        "SUM(CASE WHEN moderation_lag > 7 THEN 0 ELSE 1 END) * 100.0 / COUNT(*)"
      end

      def conditions
        [].tap do |c|
          c << "moderation_threshold_reached_at IS NOT NULL"
          c << "moderation_lag IS NOT NULL"

          if parliament
            c << "parliament_id = #{parliament.id}"
          end
        end
      end

      def parliament_id?
        parliament_id.present?
      end

      def parliament_exists
        unless Parliament.exists?(parliament_id)
          errors.add(:parliament_id, :invalid)
        end
      end

      def parliament
        if parliament_id?
          @parliament ||= Parliament.find(parliament_id)
        end
      end
    end
  end
end
