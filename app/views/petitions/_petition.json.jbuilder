json.type "petition"
json.id petition.id

json.links do
  json.self petition_url(petition, format: :json)
end if defined?(is_collection)

json.attributes do
  json.action petition.action
  json.background petition.background
  json.additional_details petition.additional_details
  json.state petition.state
  json.signature_count petition.signature_count
  json.threshold_for_referral petition.threshold_for_referral
  json.threshold_for_debate petition.threshold_for_debate

  json.created_at api_date_format(petition.created_at)
  json.updated_at api_date_format(petition.updated_at)
  json.rejected_at api_date_format(petition.rejected_at)
  json.opened_at api_date_format(petition.opened_at)

  # If a petition is open it may have had its deadline extended
  if petition.open?
    json.closed_at api_date_format(petition.deadline)
  else
    json.closed_at api_date_format(petition.closed_at)
  end

  json.completed_at api_date_format(petition.completed_at)
  json.moderation_threshold_reached_at api_date_format(petition.moderation_threshold_reached_at)
  json.referral_threshold_reached_at api_date_format(petition.referral_threshold_reached_at)
  json.referred_at api_date_format(petition.referred_at)
  json.debate_threshold_reached_at api_date_format(petition.debate_threshold_reached_at)
  json.scheduled_debate_date api_date_format(petition.scheduled_debate_date)
  json.debate_outcome_at api_date_format(petition.debate_outcome_at)
  json.archived_at api_date_format(petition.archived_at)

  # These are for petitions submitted on paper
  json.submitted_on_paper petition.submitted_on_paper
  json.submitted_on api_date_format(petition.submitted_on)

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

  if debate_outcome = petition.debate_outcome
    json.debate do
      json.debated_on debate_outcome.date
      json.transcript_url debate_outcome.transcript_url
      json.video_url debate_outcome.video_url
      json.debate_pack_url debate_outcome.debate_pack_url
      json.overview debate_outcome.overview
    end
  else
    json.debate nil
  end

  json.topics topic_codes(petition.topics)

  if (petition_page? || map_page?) && petition.published?
    json.signatures_by_country petition.signatures_by_country do |country|
      json.name country.name
      json.code country.code
      json.signature_count country.signature_count
    end

    json.signatures_by_constituency petition.signatures_by_constituency do |constituency|
      json.id constituency.constituency_id
      json.name constituency.name
      json.signature_count constituency.signature_count
    end

    json.signatures_by_region petition.signatures_by_region do |region|
      json.id region.id
      json.name region.name
      json.signature_count region.signature_count
    end
  end
end
