json.period @parliament.period
json.dissolution_at @parliament.dissolution_at
json.government @parliament.government
json.response_threshold @parliament.threshold_for_response
json.debate_threshold @parliament.threshold_for_debate

json.constituencies do
  @constituencies.each do |constituency|
    json.set! constituency.ons_code do
      json.constituency constituency.name
      json.ons_code constituency.ons_code
      json.start_date constituency.start_date
      json.end_date constituency.end_date
    end
  end
end
