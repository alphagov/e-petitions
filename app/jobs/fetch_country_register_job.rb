require 'faraday'

class FetchCountryRegisterJob < ApplicationJob
  HOST = 'https://country.register.gov.uk'
  ENDPOINT = '/records.json?page-size=500'
  TIMEOUT = 5

  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform
    countries.each do |country|
      location = Location.find_or_initialize_by(code: country['country'])

      location.name = country['name']
      location.start_date = country['start-date']
      location.end_date = country['end-date']

      if location.changed? || location.new_record?
        location.save!
      end
    end
  end

  private

  def countries
    fetch_register.body.values.map { |x| x['item'].first }
  end

  def faraday
    Faraday.new(HOST) do |f|
      f.response :follow_redirects
      f.response :json
      f.response :raise_error
      f.adapter :net_http_persistent
    end
  end

  def fetch_register
    faraday.get(ENDPOINT) do |request|
      request.options[:timeout] = TIMEOUT
      request.options[:open_timeout] = TIMEOUT
    end
  end
end
