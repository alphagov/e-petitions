@constituencies.each do |constituency|
  json.set! constituency.ons_code do
    json.mp constituency.mp_name
    json.party constituency.party
    json.constituency constituency.name
    json.ons_code constituency.ons_code
    json.start_date constituency.start_date
    json.end_date constituency.end_date
  end
end
