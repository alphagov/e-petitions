require_dependency 'constituency/api_client'
require_dependency 'constituency/api_query'

class Constituency < ActiveRecord::Base
  MP_URL = "http://www.parliament.uk/biographies/commons"

  MAPIT_HOST = "http://mapit"
  MAPIT_AREA_URL = "/area/%{ons_code}"
  MAPIT_GEOMETRY_URL = "/area/%{area_id}/geometry"
  MAPIT_POSTCODE_URL = "/nearest/%{srid}/%{easting},%{northing}"

  has_many :signatures, primary_key: :external_id
  has_many :petitions, through: :signatures

  validates :name, presence: true, length: { maximum: 100 }
  validates :external_id, presence: true, length: { maximum: 30 }
  validates :ons_code, presence: true, format: %r[\A(?:E|W|S|N)\d{8}\z]
  validates :mp_id, length: { maximum: 30 }
  validates :mp_name, length: { maximum: 100 }

  before_validation if: :name_changed? do
    self.slug = name.parameterize
  end

  class << self
    def find_by_postcode(postcode)
      results = query.fetch(postcode)

      if attributes = results.first
        constituency = find_or_initialize_by(external_id: attributes[:external_id])
        constituency.attributes = attributes
        if constituency.changed? || constituency.new_record?
          constituency.save!
        end

        constituency
      end
    end

    def refresh
      find_each { |c| c.refresh }
    end

    private

    def query
      ApiQuery.new
    end
  end

  def sitting_mp?
    mp_id?
  end

  def mp_url
    "#{MP_URL}/#{mp_name.parameterize}/#{mp_id}"
  end

  def to_param
    slug
  end

  def example_postcode
    super || fetch_and_save_example_postcode
  end

  def reset_example_postcode
    update(example_postcode: nil)
  end

  def refresh
    if example_postcode
      constituency = self.class.find_by_postcode(example_postcode)

      if external_id != constituency.external_id
        raise RuntimeError, <<-ERROR.squish
          mismatched constituencies when refreshing
          with example postcode #{example_postcode.inspect}
          - expected: #{external_id}, actual: #{constituency.external_id}
        ERROR
      end
    end
  end

  private

  def fetch_and_save_example_postcode
    if postcode = fetch_example_postcode
      constituency = self.class.find_by_postcode(postcode)

      if external_id != constituency.external_id
        raise RuntimeError, <<-ERROR.squish
          mismatched constituencies when setting
          example postcode #{postcode.inspect}
          - expected: #{external_id}, actual: #{constituency.external_id}
        ERROR
      end

      update(example_postcode: postcode)
    end

    postcode

  rescue Faraday::Error => e
    Appsignal.send_exception(e) if defined?(Appsignal)
    return nil
  end

  def fetch_example_postcode
    if area = fetch_area
      fetch_central_postcode(area["id"])
    end
  end

  def fetch_central_postcode(area_id)
    if geometry = fetch_geometry(area_id)
      fetch_nearest_postcode(geometry["centre_e"], geometry["centre_n"])
    end
  end

  def fetch_nearest_postcode(easting, northing)
    if postcode = fetch_postcode(easting, northing)
      PostcodeSanitizer.call(postcode)
    end
  end

  def faraday
    @faraday ||= Faraday.new(MAPIT_HOST) do |f|
      f.response :follow_redirects
      f.response :raise_error
      f.adapter  :net_http_persistent
    end
  end

  def get(path)
    faraday.get(path) do |request|
      request.options[:timeout] = 5
      request.options[:open_timeout] = 5
    end
  end

  def fetch_area
    response = get(MAPIT_AREA_URL % { ons_code: ons_code })

    if response.success?
      JSON.load(response.body)
    else
      nil
    end
  end

  def fetch_geometry(area_id)
    response = get(MAPIT_GEOMETRY_URL % { area_id: area_id })

    if response.success?
      JSON.load(response.body)
    else
      nil
    end
  end

  def fetch_postcode(easting, northing)
    response = get(MAPIT_POSTCODE_URL % { srid: 27700, easting: easting, northing: northing })

    if response.success?
      json = JSON.load(response.body)
      json["postcode"]["postcode"]
    else
      nil
    end
  end
end
