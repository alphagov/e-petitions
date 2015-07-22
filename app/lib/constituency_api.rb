require 'faraday'
require 'nokogiri'
require 'postcode_sanitizer'

module ConstituencyApi
  class Constituency
    attr_reader :id, :name, :mp

    def initialize(id, name, mp = nil)
      @id, @name, @mp = id, name, mp
    end

    def ==(other)
      other.is_a?(self.class) && id == other.id && name == other.name && mp == other.mp
    end
    alias_method :eql?, :==
  end

  class Mp
    attr_reader :id, :name, :start_date
    URL = "http://www.parliament.uk/biographies/commons/%{name}/%{id}"

    def initialize(id, name, start_date)
      @id, @name, @start_date = id, name, start_date.to_date
    end

    def url
      URL % { name: name.parameterize, id: id }
    end

    def ==(other)
      other.is_a?(self.class) && id == other.id && name == other.name && start_date == other.start_date
    end
    alias_method :eql?, :==
  end

  class Client
    API_HOST = 'http://data.parliament.uk'
    API_ENDPOINT = '/membersdataplatform/services/mnis/Constituencies/%{postcode}/'
    TIMEOUT = 5

    def call(postcode)
      faraday.get(path(postcode)) do |request|
        request.options[:timeout] = TIMEOUT
        request.options[:open_timeout] = TIMEOUT
      end
    end

    private

    def faraday
      Faraday.new(API_HOST) do |f|
        f.response :follow_redirects
        f.response :raise_error
        f.adapter Faraday.default_adapter
      end
    end

    def path(postcode)
      API_ENDPOINT % { postcode: escape_path(postcode) }
    end

    def escape_path(value)
      Rack::Utils.escape_path(value)
    end
  end

  class Query
    CONSTITUENCIES    = '//Constituencies/Constituency'
    CONSTITUENCY_ID   = './Constituency_Id'
    CONSTITUENCY_NAME = './Name'

    CURRENT_MP = './RepresentingMembers/RepresentingMember[1]'
    MP_ID      = './Member_Id'
    MP_NAME    = './Member'
    MP_DATE    = './StartDate'

    def initialize(postcode)
      @postcode = postcode
    end

    def fetch
      response = client.call(postcode)

      if response.success?
        parse(response.body)
      else
        []
      end
    rescue Faraday::Error::ResourceNotFound => e
      return []
    rescue Faraday::Error => e
      Appsignal.send_exception(e) if defined?(Appsignal)
      return []
    end

    private

    def client
      @client ||= Client.new
    end

    def postcode
      PostcodeSanitizer.call(@postcode)
    end

    def parse(body)
      xml = Nokogiri::XML(body)

      xml.xpath(CONSTITUENCIES).map do |node|
        id   = node.xpath(CONSTITUENCY_ID).text
        name = node.xpath(CONSTITUENCY_NAME).text

        if mp = node.at_xpath(CURRENT_MP)
          Constituency.new(id, name, parse_mp(mp))
        else
          Constituency.new(id, name)
        end
      end
    end

    def parse_mp(node)
      id   = node.xpath(MP_ID).text
      name = node.xpath(MP_NAME).text
      date = node.xpath(MP_DATE).text

      Mp.new(id, name, date)
    end
  end

  def self.constituency(postcode)
    constituencies(postcode).first
  end

  def self.constituencies(postcode)
    Query.new(postcode).fetch
  end
end
