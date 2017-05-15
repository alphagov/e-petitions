class ImportConstituenciesJob < ApplicationJob
  HOST = "http://data.parliament.uk"
  ENDPOINT = "/membersdataplatform/services/mnis/ReferenceData/Constituencies/"
  TIMEOUT = 30
  UTF_BOM = /\A\xEF\xBB\xBF/

  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform
    current_constituencies.each do |row|
      constituency = Constituency.find_or_initialize_by(external_id: row["Constituency_Id"])

      constituency.name = row["Name"]
      constituency.ons_code = row["ONSCode"]
      constituency.example_postcode = example_postcodes[row["ONSCode"]]

      if constituency.changed? || constituency.new_record?
        constituency.save!
      end
    end
  end

  private

  def constituencies
    response = fetch_constituencies

    # The response from the Parliament API includes a BOM (byte-order mark)
    # and JSON.parse barfs on this so remove it if it is present
    body = response.body.force_encoding("utf-8")
    body = body[1..-1] if body =~ UTF_BOM
    json = JSON.parse(body)

    json["Constituencies"]["Constituency"]
  end

  def current_constituencies
    constituencies.select { |c| c["EndDate"].nil? }
  end

  def faraday
    Faraday.new(HOST) do |f|
      f.response :follow_redirects
      f.response :raise_error
      f.adapter :net_http_persistent
    end
  end

  def fetch_constituencies
    faraday.get(ENDPOINT) do |request|
      request.headers["Accept"] = "application/json"
      request.options[:timeout] = TIMEOUT
      request.options[:open_timeout] = TIMEOUT
    end
  end

  def example_postcodes
    @example_postcodes ||= YAML.load_file(Rails.root.join("data", "example_postcodes.yml"))
  end
end
