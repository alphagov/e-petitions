require 'faraday'
require 'postcode_sanitizer'

class Constituency < ActiveRecord::Base
  class ApiClient
    HOST = 'http://data.parliament.uk'
    ENDPOINT = '/membersdataplatform/services/mnis/Constituencies/%{postcode}/'
    TIMEOUT = 5

    def call(postcode)
      faraday.get(path(postcode)) do |request|
        request.options[:timeout] = TIMEOUT
        request.options[:open_timeout] = TIMEOUT
      end
    end

    private

    def faraday
      @faraday ||= Faraday.new(HOST) do |f|
        f.response :follow_redirects
        f.response :raise_error
        f.adapter  :net_http_persistent
      end
    end

    def path(postcode)
      ENDPOINT % { postcode: escape_path(postcode) }
    end

    def escape_path(value)
      Rack::Utils.escape_path(sanitize(value))
    end

    def sanitize(value)
      PostcodeSanitizer.call(value)
    end
  end
end
