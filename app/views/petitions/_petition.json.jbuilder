json.type "petition"
json.id petition.id

json.links do
  json.self petition_url(petition, format: params[:format])
end if defined?(is_collection)

json.attributes do
  json.action petition.action
  json.background petition.background
  json.additional_details petition.additional_details
  json.state petition.state
  json.signature_count petition.signature_count

  json.created_at api_date_format(petition.created_at)
  json.updated_at api_date_format(petition.updated_at)
  json.open_at api_date_format(petition.open_at)
  json.closed_at api_date_format(petition.closed_at)
  json.government_response_at api_date_format(petition.government_response_at)
  json.scheduled_debate_date api_date_format(petition.scheduled_debate_date)
  json.debate_threshold_reached_at api_date_format(petition.debate_threshold_reached_at)
  json.rejected_at api_date_format(petition.rejected_at)
  json.debate_outcome_at api_date_format(petition.debate_outcome_at)
  json.moderation_threshold_reached_at api_date_format(petition.moderation_threshold_reached_at)
  json.response_threshold_reached_at api_date_format(petition.response_threshold_reached_at)

  if petition.open?
    json.creator_name petition.creator_name
  else
    json.creator_name nil
  end

  if petition.rejected?
    json.rejection do
      json.code petition.rejection_code
      json.details petition.rejection_details
    end
  else
    json.rejection nil
  end

  if petition.government_response?
    json.government_response do
      json.summary petition.government_response_summary
      json.details petition.government_response_details
      json.created_at api_date_format(petition.government_response_created_at)
      json.updated_at api_date_format(petition.government_response_updated_at)
    end
  else
    json.government_response nil
  end

  if petition.debate_outcome?
    json.debate do
      json.debated_on petition.debate_date
      json.transcript_url petition.debate_transcript_url
      json.video_url petition.debate_video_url
      json.overview petition.debate_overview
    end
  else
    json.debate nil
  end

  if petition_page?
    json.signatures_by_country petition.signatures_by_country do |country|
      json.name country.name
      json.signature_count country.signature_count
    end

    json.signatures_by_constituency petition.signatures_by_constituency do |constituency|
      json.name constituency.name
      json.ons_code constituency.ons_code
      json.mp constituency.mp_name
      json.signature_count constituency.signature_count
    end
  end
end
