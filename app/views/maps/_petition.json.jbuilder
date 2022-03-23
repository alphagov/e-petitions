json.id @petition.id
json.action @petition.action
json.signature_count @petition.signature_count
json.petition_url petition_url(@petition)

if @petition.open?
  json.sign_petition_url new_petition_signature_url(@petition)
else
  json.sign_petition_url nil
end

countries = @petition.signatures_by_country

if countries.empty?
  json.set! :signatures_by_country, {}
else
  json.signatures_by_country do
    countries.each do |country|
      json.set! country.code, country.signature_count
    end
  end
end

constituencies = @petition.signatures_by_constituency

if constituencies.empty?
  json.set! :signatures_by_constituency, {}
else
  json.signatures_by_constituency do
    constituencies.each do |constituency|
      json.set! constituency.constituency_id, constituency.signature_count
    end
  end
end

regions = @petition.signatures_by_region

if regions.empty?
  json.set! :signatures_by_region, {}
else
  json.signatures_by_region do
    regions.each do |region|
      json.set! region.id, region.signature_count
    end
  end
end
