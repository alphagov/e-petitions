json.cache! :constituencies, expires_in: 1.hour do
  @constituencies.each do |constituency|
    json.set! constituency.ons_code do
      json.mp constituency.mp_name
      json.party constituency.party
      json.constituency constituency.name
      json.ons_code constituency.ons_code
    end
  end
end
