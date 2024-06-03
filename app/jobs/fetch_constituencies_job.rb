class FetchConstituenciesJob < ApplicationJob
  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform
    constituencies.each do |external_id, name, ons_code, start_date, end_date|
      begin
        retried = false

        Constituency.for(external_id) do |constituency|
          constituency.name = name
          constituency.ons_code = ons_code
          constituency.example_postcode = example_postcodes[ons_code]
          constituency.region_id = regions[external_id]
          constituency.start_date = start_date
          constituency.end_date = end_date

          if mp = mps[external_id]
            constituency.mp_id = mp.id
            constituency.mp_name = mp.name
            constituency.mp_date = mp.date
            constituency.party = mp.party
          else
            constituency.mp_id = nil
            constituency.mp_name = nil
            constituency.mp_date = nil
            constituency.party = nil
          end

          constituency.save!
        end
      rescue ActiveRecord::RecordNotUnique => e
        retry unless retried
        retried = true
      end
    end
  end

  private

  def constituencies
    @constituencies ||= Feed::Constituencies.new
  end

  def members
    @members ||= Feed::Members.new
  end

  def mps
    @mps ||= members.inject({}) { |h, m| h[m.constituency_id] = m; h }
  end

  def constituency_regions
    @constituency_regions ||= Feed::ConstituencyRegions.new
  end

  def regions
    @regions ||= constituency_regions.inject({}) { |h, c| h[c.constituency_id] = c.region_id; h }
  end

  def example_postcodes
    @example_postcodes ||= YAML.load_file(Rails.root.join("data", "example_postcodes.yml"))
  end
end
