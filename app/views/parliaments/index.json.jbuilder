@parliaments.each do |parliament|
  json.set! parliament.id do
    json.period parliament.period
    json.opening_at parliament.opening_at
    json.dissolution_at parliament.dissolution_at
    json.government parliament.government
    json.archived_at parliament.archived_at
    json.response_threshold parliament.threshold_for_response
    json.debate_threshold parliament.threshold_for_debate
    json.election_date parliament.election_date
  end
end
