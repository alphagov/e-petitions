module Statistics
  module SignatureCounts
    class Report < Base::Report
      attr_reader :scope, :parliament_id
      attr_reader :breakdown, :start, :finish

      validate :parliament_exists, if: :parliament_id?
      validates :breakdown, presence: true, inclusion: { in: %w[none country region constituency] }

      def initialize(scope, parliament_id, breakdown, start, finish)
        @scope = scope
        @parliament_id = parliament_id
        @breakdown = breakdown
        @start = start
        @finish = finish
      end

      def filename
        "#{filename_parts.join('-')}.csv"
      end

      def content
        CSV.generate do |csv|
          csv << headers

          rows.each do |row|
            csv << row
          end
        end
      end

      private

      def sql
        case breakdown
        when 'region'
          <<~SQL
            SELECT
              r.name AS region,
              r.external_id AS id,
              r.ons_code,
              COALESCE(SUM(q.total_signatures)::int, 0) AS total_signatures,
              COALESCE(SUM(q.unique_emails)::int, 0) AS unique_emails
            FROM regions AS r
            INNER JOIN constituencies AS c ON r.external_id = c.region_id
            LEFT JOIN (
              SELECT
                s.constituency_id,
                COUNT(*) AS total_signatures,
                COUNT(DISTINCT s.uuid) AS unique_emails
              FROM #{signatures} AS s
              INNER JOIN #{petitions} AS p ON s.petition_id = p.id
              WHERE (#{conditions.join(') AND (')})
              GROUP BY s.constituency_id
            ) AS q ON c.external_id = q.constituency_id
            GROUP BY r.name, r.external_id, r.ons_code
            ORDER BY r.name;
          SQL

        when 'country'
          <<~SQL
            SELECT
              l.name AS country,
              l.code AS iso_code,
              COALESCE(q.total_signatures, 0) AS total_signatures,
              COALESCE(q.unique_emails, 0) AS unique_emails
            FROM locations AS l
            LEFT JOIN (
              SELECT
                s.location_code,
                COUNT(*) AS total_signatures,
                COUNT(DISTINCT s.uuid) AS unique_emails
              FROM #{signatures} AS s
              INNER JOIN #{petitions} AS p ON s.petition_id = p.id
              WHERE (#{conditions.join(') AND (')})
              GROUP BY s.location_code
            ) AS q ON l.code = q.location_code
            WHERE
              (l.start_date IS NULL OR l.start_date <= CURRENT_DATE)
            AND
              (l.end_date IS NULL OR l.end_date >= CURRENT_DATE)
            ORDER BY l.name;
          SQL

        when 'constituency'
          <<~SQL
            SELECT
              c.name AS constituency,
              c.external_id AS id,
              c.ons_code,
              c.mp_name,
              COALESCE(q.total_signatures, 0) AS total_signatures,
              COALESCE(q.unique_emails, 0) AS unique_emails
            FROM constituencies AS c
            LEFT JOIN (
              SELECT
                s.constituency_id,
                COUNT(*) AS total_signatures,
                COUNT(DISTINCT s.uuid) AS unique_emails
              FROM #{signatures} AS s
              INNER JOIN #{petitions} AS p ON s.petition_id = p.id
              WHERE (#{conditions.join(') AND (')})
              GROUP BY s.constituency_id
            ) AS q ON c.external_id = q.constituency_id
            ORDER BY c.name;
          SQL

        when 'none'
          <<~SQL
            SELECT
              COUNT(*) AS total_signatures,
              COUNT(DISTINCT s.uuid) AS unique_emails
            FROM #{signatures} AS s
            INNER JOIN #{petitions} AS p ON s.petition_id = p.id
            WHERE (#{conditions.join(') AND (')})
          SQL

        else
          raise RuntimeError, "Unexpected geographical breakdown: #{breakdown}"
        end
      end

      def conditions
        [].tap do |c|
          c << "s.state = 'validated'"

          if parliament
            c << "p.state IN ('closed')"
            c << "p.parliament_id = ?"
          else
            c << "p.state IN ('open', 'closed')"
          end

          if start?
            c << "s.validated_at >= ?"
          end

          if finish?
            c << "s.validated_at < ?"
          end
        end
      end

      def binds
        [].tap do |b|
          if parliament
            b << parliament.id
          end

          if start?
            b << start.beginning_of_day
          end

          if finish?
            b << finish.tomorrow.beginning_of_day
          end
        end
      end

      def headers
        case breakdown
        when 'none'
          return ['Total Signatures', 'Unique Email Addresses']
        when 'country'
          return ['Country', 'ISO Code', 'Total Signatures', 'Unique Email Addresses']
        when 'region'
          return ['Region', 'ID', 'ONS Code', 'Total Signatures', 'Unique Email Addresses']
        when 'constituency'
          return ['Constituency', 'ID', 'ONS Code', 'MP Name', 'Total Signatures', 'Unique Email Addresses']
        else
          raise RuntimeError, "Unexpected geographical breakdown: #{breakdown}"
        end
      end

      def petitions
        scope == 'current' ? 'petitions' : 'archived_petitions'
      end

      def signatures
        scope == 'current' ? 'signatures' : 'archived_signatures'
      end

      def breakdown?
        breakdown != 'none'
      end

      def start?
        start.present?
      end

      def finish?
        finish.present?
      end

      def filename_parts
        [].tap do |f|
          f << (scope == 'current' ? 'signatures' : 'archived-signatures')
          f << "by-#{breakdown}" if breakdown?
          f << "for-#{parliament.period}-parliament" if parliament_id?
          f << "from-#{start.iso8601}" if start?
          f << "to-#{finish.iso8601}" if finish?
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
