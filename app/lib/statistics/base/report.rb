require 'csv'

module Statistics
  module Base
    class Report
      include ActiveModel::Validations

      delegate :connection, :sanitize_sql_array, to: :base
      delegate :select_rows, to: :connection

      def filename
        "report.csv"
      end

      def mime_type
        "text/csv"
      end

      def content
        ""
      end

      def attachment
        { mime_type: mime_type, content: content }
      end

      private

      def base
        ActiveRecord::Base
      end

      def rows
        select_rows(sanitize_sql_array([sql, *binds]))
      end

      def binds
        []
      end
    end
  end
end
