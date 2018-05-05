require 'faraday'

class RefreshConstituencyPartyJob < ApplicationJob
  HOST = "http://data.parliament.uk"
  ENDPOINT = "/membersdataplatform/services/mnis/members/query/House=Commons%7CIsEligible=true/"
  TIMEOUT = 5

  MEMBERS    = "//Members/Member"
  MP_ID      = "./@Member_Id"
  MP_NAME    = "./FullTitle"
  MP_PARTY   = "./Party"

  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform
    Constituency.find_each do |constituency|
      if member = members[constituency.mp_id]
        constituency.update!(party: member[:party])
      else
        constituency.update!(mp_id: nil, mp_name: nil, mp_date: nil, party: nil)
      end
    end
  end

  private

  def members
    @members ||= load_members
  end

  def load_members
    response = fetch_members

    if response.success?
      Hash[parse(response.body)]
    else
      {}
    end
  rescue Faraday::Error => e
    Appsignal.send_exception(e)
    return {}
  end

  def parse(body)
    xml = Nokogiri::XML(body)

    xml.xpath(MEMBERS).map do |node|
      [
        node.xpath(MP_ID).text,
        {}.tap { |attrs|
          attrs[:id]    = node.xpath(MP_ID).text
          attrs[:name]  = node.xpath(MP_NAME).text
          attrs[:party] = node.xpath(MP_PARTY).text
        }
      ]
    end
  end

  def faraday
    Faraday.new(HOST) do |f|
      f.response :follow_redirects
      f.response :raise_error
      f.adapter :net_http_persistent
    end
  end

  def fetch_members
    faraday.get(ENDPOINT) do |request|
      request.options[:timeout] = TIMEOUT
      request.options[:open_timeout] = TIMEOUT
    end
  end
end
