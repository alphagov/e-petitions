require 'nokogiri'

class Constituency < ActiveRecord::Base
  class ApiQuery
    CONSTITUENCIES    = '//Constituencies/Constituency'
    CONSTITUENCY_ID   = './Constituency_Id'
    CONSTITUENCY_NAME = './Name'
    CONSTITUENCY_CODE = './ONSCode'

    CURRENT_MP = './RepresentingMembers/RepresentingMember[1]'
    MP_ID      = './Member_Id'
    MP_NAME    = './Member'
    MP_DATE    = './StartDate'

    def fetch(postcode)
      response = client.call(postcode)

      if response.success?
        parse(response.body)
      else
        []
      end
    rescue Faraday::ResourceNotFound, Faraday::ClientError => e
      return []
    rescue Faraday::Error => e
      Appsignal.send_exception(e) if defined?(Appsignal)
      return []
    end

    def self.before_remove_const
      Thread.current[:__api_client__] = nil
    end

    private

    def client
      Thread.current[:__api_client__] ||= ApiClient.new
    end

    def parse(body)
      xml = Nokogiri::XML(body)

      xml.xpath(CONSTITUENCIES).map do |node|
        {}.tap do |attrs|
          attrs[:name]        = node.xpath(CONSTITUENCY_NAME).text
          attrs[:external_id] = node.xpath(CONSTITUENCY_ID).text
          attrs[:ons_code]    = node.xpath(CONSTITUENCY_CODE).text

          if mp = node.at_xpath(CURRENT_MP)
            attrs[:mp_id] = mp.xpath(MP_ID).text
            attrs[:mp_name] = mp.xpath(MP_NAME).text
            attrs[:mp_date] = mp.xpath(MP_DATE).text
          end
        end
      end
    end
  end
end
