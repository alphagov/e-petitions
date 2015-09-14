json.type "archived-petition"
json.id petition.id

json.links do
  json.self archived_petition_url(petition, format: params[:format])
end if defined?(is_collection)

json.attributes do
  json.title petition.title
  json.description petition.description
  json.state petition.state
  json.signature_count petition.signature_count
  json.opened_at api_date_format(petition.opened_at)
  json.closed_at api_date_format(petition.closed_at)
  json.created_at api_date_format(petition.created_at)
  json.updated_at api_date_format(petition.updated_at)

  if petition.rejected?
    json.rejection do
      json.details petition.reason_for_rejection
    end
  else
    json.rejection nil
  end

  if petition.response?
    json.government_response do
      json.details petition.response
    end
  else
    json.government_response nil
  end
end
