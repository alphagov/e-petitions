require 'faraday'

class FetchMembersJob < ApplicationJob
  HOST = "https://business.senedd.wales"
  TIMEOUT = 5

  ENDPOINTS = {
    "en-GB": "/mgwebservice.asmx/GetCouncillorsByWard",
    "cy-GB": "/mgwebservicew.asmx/GetCouncillorsByWard"
  }

  WARDS = "/councillorsbyward/wards/ward"
  CONSTITUENCY = ".//wardtitle"
  REGION = ".//districttitle"
  MEMBERS = ".//councillor"
  MEMBER_ID = ".//councillorid"
  MEMBER_NAME = ".//fullusername"
  PARTY = ".//politicalpartytitle"

  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  before_perform do
    @translated_members = load_translated_members
  end

  def perform
    return if @translated_members.empty?

    Member.transaction do
      Member.update_all(region_id: nil, constituency_id: nil)

      @translated_members.each do |id, attributes|
        retried = false

        begin
          Member.for(id) { |member| member.update!(attributes) }
        rescue ActiveRecord::RecordNotUnique => e
          if retried
            raise e
          else
            retried = true
            retry
          end
        end
      end
    end
  end

  private

  def load_translated_members
    {}.tap do |hash|
      members(:"en-GB").each do |member|
        hash[member[:id]] = {}.tap do |row|
          row[:name_en] = member[:name]
          row[:party_en] = member[:party]
          row[:constituency_id] = member[:constituency_id]
          row[:region_id] = member [:region_id]
        end
      end

      members(:"cy-GB").each do |member|
        hash.fetch(member[:id]).tap do |row|
          row[:name_cy] = member[:name]
          row[:party_cy] = member[:party]
        end
      end
    end
  end

  def members(locale)
    I18n.with_locale(locale) { load_members }
  end

  def constituency_maps
    @constituency_maps ||= {}
  end

  def constituency_map
    constituency_maps[I18n.locale] ||= normalize_map(Constituency.pluck(:name, :id))
  end

  def region_maps
    @region_maps ||= {}
  end

  def region_map
    region_maps[I18n.locale] ||= normalize_map(Region.pluck(:name, :id))
  end

  def load_members
    response = fetch_members

    if response.success?
      parse(response.body)
    else
      []
    end
  rescue Faraday::Error => e
    Appsignal.send_exception(e)
    return []
  end

  def parse(body)
    xml = Nokogiri::XML(body)

    parse_wards(body).inject([]) do |members, node|
      if constituency_member?(node)
        members << parse_constituency(node)
      else
        members += parse_regions(node)
      end

      members
    end
  end

  def parse_wards(body)
    Nokogiri::XML(body).xpath(WARDS)
  end

  def constituency_member?(node)
    node.at_xpath(CONSTITUENCY).text.strip != "No Ward"
  end

  def parse_constituency(node)
    id = Integer(node.at_xpath(MEMBER_ID).text)
    name = node.at_xpath(MEMBER_NAME).text.strip
    party = node.at_xpath(PARTY).text.strip
    constituency_name = node.at_xpath(CONSTITUENCY).text.strip
    constituency_id = constituency_map.fetch(constituency_name.parameterize)

    { id: id, name: name, party: party, constituency_id: constituency_id }
  end

  def parse_regions(node)
    node.xpath(MEMBERS).map do |member|
      id = Integer(member.at_xpath(MEMBER_ID).text)
      name = member.at_xpath(MEMBER_NAME).text.strip
      party = member.at_xpath(PARTY).text.strip
      region_name = member.at_xpath(REGION).text.strip
      region_id = region_map.fetch(region_name.parameterize)

      { id: id, name: name, party: party, region_id: region_id }
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
    faraday.get(endpoint) do |request|
      request.options[:timeout] = TIMEOUT
      request.options[:open_timeout] = TIMEOUT
    end
  end

  def endpoint
    ENDPOINTS[I18n.locale]
  end

  def normalize_map(mappings)
    mappings.map { |key, id| [key.parameterize, id] }.to_h
  end
end
