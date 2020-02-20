module Statistics
  class << self
    def moderation(by: "month")
      table_name = "petitions"

      unless by.in?(%w[week month])
        raise ArgumentError, "invalid value for by: #{by.inspect} - must be either week or month"
      end

      period = "DATE_TRUNC('#{by}', moderation_threshold_reached_at)"
      expression = "SUM(CASE WHEN moderation_lag > 7 THEN 0 ELSE 1 END) * 100.0 / COUNT(*)"

      format = \
        case by
        when "week"
          "'DD Mon YYYY'"
        when "month"
          "'Mon YYYY'"
        end

      conditions = []
      conditions << "moderation_threshold_reached_at IS NOT NULL"
      conditions << "moderation_lag IS NOT NULL"

      select_rows <<-SQL.strip_heredoc
        SELECT
          TO_CHAR(#{period}, #{format}) AS period,
          ROUND(#{expression}, 1) AS percentage_within_target
        FROM
          #{table_name}
        WHERE
          #{conditions.join(' AND ')}
        GROUP BY
          #{period}
        ORDER BY
          #{period}
      SQL
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def select_rows(sql)
      connection.select_rows(sql)
    end
  end
end
