json.type "petition"
json.id petition.id

json.links do
  json.self petition_url(petition, format: :json)
end if defined?(is_collection)

json.attributes do
  json.action petition.action
  json.background petition.background
  json.additional_details petition.additional_details
  json.committee_note petition.committee_note
  json.state petition.state
  json.signature_count petition.signature_count

  json.created_at api_date_format(petition.created_at)
  json.updated_at api_date_format(petition.updated_at)
  json.rejected_at api_date_format(petition.rejected_at)
  json.opened_at api_date_format(petition.opened_at)
  json.closed_at api_date_format(petition.closed_at)
  json.moderation_threshold_reached_at api_date_format(petition.moderation_threshold_reached_at)
  json.response_threshold_reached_at api_date_format(petition.response_threshold_reached_at)
  json.government_response_at api_date_format(petition.government_response_at)
  json.debate_threshold_reached_at api_date_format(petition.debate_threshold_reached_at)
  json.debate_scheduled_at api_date_format(petition.debate_scheduled_at)
  json.scheduled_debate_date api_date_format(petition.scheduled_debate_date)
  json.debate_outcome_at api_date_format(petition.debate_outcome_at)

  if petition.open?
    json.creator_name petition.creator_name
  else
    json.creator_name nil
  end

  if rejection = petition.rejection
    json.rejection do
      json.code rejection.code
      json.details rejection.details
    end
  else
    json.rejection nil
  end

  if response = petition.government_response
    json.government_response do
      json.responded_on api_date_format(response.responded_on)
      json.summary response.summary
      json.details response.details
      json.created_at api_date_format(response.created_at)
      json.updated_at api_date_format(response.updated_at)
    end
  else
    json.government_response nil
  end

  if debate_outcome = petition.debate_outcome
    json.debate do
      json.debated_on debate_outcome.date
      json.transcript_url debate_outcome.transcript_url
      json.video_url debate_outcome.video_url
      json.debate_pack_url debate_outcome.debate_pack_url
      json.public_engagement_url debate_outcome.public_engagement_url
      json.debate_summary_url debate_outcome.debate_summary_url
      json.overview debate_outcome.overview
    end
  else
    json.debate nil
  end

  json.departments departments(petition.departments) do |department|
    json.acronym department.acronym
    json.name department.name
    json.url department.url
  end

  json.topics topic_codes(petition.topics)

  if petition_page? && petition.published?
    json.signatures_by_country petition.signatures_by_country do |country|
      json.name country.name
      json.code country.code
      json.signature_count country.signature_count
    end

    json.signatures_by_constituency petition.signatures_by_constituency do |constituency|
      json.name constituency.name
      json.ons_code constituency.ons_code
      json.mp constituency.mp_name
      json.signature_count constituency.signature_count
    end

    json.signatures_by_region petition.signatures_by_region do |region|
      json.name region.name
      json.ons_code region.ons_code
      json.signature_count region.signature_count
    end

    json.other_parliamentary_business petition.emails do |email|
      json.subject email.subject
      json.body markdown_to_text(email.body)
      json.created_at api_date_format(email.created_at)
      json.updated_at api_date_format(email.updated_at)
    end
  end
end
