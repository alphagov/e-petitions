json.id @parliament.id
json.period @parliament.period

json.attributes do
  json.dissolution_at @parliament.opening_at
  json.dissolution_at @parliament.dissolution_at
  json.government @parliament.government
  json.archived_at @parliament.archived_at
  json.response_threshold @parliament.threshold_for_response
  json.debate_threshold @parliament.threshold_for_debate
  json.election_date @parliament.election_date
end
json.constituencies @parliament.constituencies.each do |constituency|
                        json.mp constituency.mp_name
                        json.party constituency.party
                        json.constituency constituency.name
                        json.ons_code constituency.ons_code
                        json.start_date constituency.start_date
                        json.end_date constituency.end_date
end
