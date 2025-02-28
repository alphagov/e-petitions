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
    MP_START   = './StartDate'
    MP_END     = './EndDate'

    IGNORE_EXCEPTIONS = [
      Faraday::ResourceNotFound,
      Faraday::ClientError,
      Faraday::TimeoutError
    ]

    NOTIFY_EXCEPTIONS = [
      Faraday::Error
    ]

    def fetch(postcode)
      response = client.call(postcode)

      if response.success?
        parse(response.body)
      else
        []
      end
    rescue *IGNORE_EXCEPTIONS => e
      return []
    rescue *NOTIFY_EXCEPTIONS => e
      Appsignal.send_exception(e)
      return []
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
            if mp.at_xpath(MP_END).text.present?
              attrs.merge!(mp_id: nil, mp_name: nil, mp_date: nil)
            else
              attrs[:mp_id] = mp.xpath(MP_ID).text
              attrs[:mp_name] = mp.xpath(MP_NAME).text
              attrs[:mp_date] = mp.xpath(MP_START).text
            end
          end
        end
      end
    end
  end
end
