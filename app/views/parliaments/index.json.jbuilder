json.array! @parliaments.each do |parliament|
  json.period parliament.period
  json.dissolution_at parliament.dissolution_at
  json.government parliament.government
  json.response_threshold parliament.threshold_for_response
  json.debate_threshold parliament.threshold_for_debate
end
