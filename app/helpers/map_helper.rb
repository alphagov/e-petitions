module MapHelper
  class MapPreview
    BASE_IMAGE   = Rails.root.join('app', 'assets', 'images', 'map', 'base.png')
    EPSILON      = 0.0005
    COLOR_SCALE  = 0.8
    STROKE_COLOR = 0x3C3C3BFF # Dark Grey
    FILL_COLOR   = 0xC9187EFF # Pink

    class Polygon
      # These are 'magic' numbers derived from the boundary of Wales
      # and designed to scale the polygons to fit in the center of the
      # 1200 x 630 pixel image recommended size of OpenGraph images.
      MIN_X  = 169269.127353594
      MIN_Y  = 165631.769405093
      SCALE  = 0.00240226
      HEIGHT = 550
      PX = 376
      PY = 40

      attr_reader :polygon, :fill_color

      def initialize(polygon, fill_color)
        @polygon, @fill_color = polygon, fill_color
      end

      def stroke_color
        STROKE_COLOR
      end

      def path
        points.map(&method(:transform))
      end

      private

      def points
        polygon.exterior_ring.points
      end

      def transform(point)
        [
          ((point.x - MIN_X) * SCALE).round + PX,
          (HEIGHT - ((point.y - MIN_Y) * SCALE).round) + PY
        ]
      end
    end

    class ConstituencyFeature
      attr_reader :boundary, :journal, :max_percentage

      def initialize(boundary, journal, max_percentage)
        @boundary, @journal, @max_percentage = boundary, journal, max_percentage
      end

      def polygons
        if multi_polygon?
          boundary.each do |polygon|
            yield Polygon.new(polygon, fill_color)
          end
        else
          yield Polygon.new(boundary, fill_color)
        end
      end

      private

      def multi_polygon?
        boundary.geometry_type == RGeo::Feature::MultiPolygon
      end

      def fill_color
        @fill_color ||= ChunkyPNG::Color.fade(FILL_COLOR, opacity)
      end

      def opacity
        @opacity ||= calculate_opacity
      end

      def calculate_opacity
        percent_count < EPSILON ? 0 : (percent_count * color_scale).floor
      end

      def color_scale
        @color_scale ||= (1 / max_percentage) * COLOR_SCALE * 255
      end

      def percent_count
        journal.try(:percent_count) || 0
      end
    end

    attr_reader :petition, :png
    delegate :signatures_by_constituency, to: :petition

    def initialize(petition)
      @petition = petition
      @png = ChunkyPNG::Canvas.from_file(BASE_IMAGE)
    end

    def draw(path, stroke, fill)
      png.polygon(path, stroke, fill)
    end

    def constituencies
      Constituency.all.map do |c|
        yield ConstituencyFeature.new(c.boundary.projection, journals[c.id], max_value)
      end
    end

    def to_blob(encoding = :fast_rgb)
      png.to_blob(encoding)
    end

    private

    def journals
      @journals ||= signatures_by_constituency.map { |j| [j.constituency_id, j ] }.to_h
    end

    def max_value
      @max_value ||= journals.map { |_, v| v.percent_count }.max
    end
  end

  def map_preview(petition)
    key = [petition, :map_preview]

    options = {
      expires_in: 15.minutes,
      race_condition_ttl: 10.seconds
    }

    Rails.cache.fetch(key, options)  do
      builder = MapPreview.new(petition)
      yield builder
      builder.to_blob
    end
  end
end
