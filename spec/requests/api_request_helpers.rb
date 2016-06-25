module ApiRequestHelpers
  include TimestampsSpecHelper

  def assert_serialized_rejection(petition, attributes)
    if petition.rejected?
      expect(attributes["rejection"]).to be_a Hash
      attributes["rejection"].tap do |rejection|
        expect(rejection["code"]).to eq(petition.rejection.code)
        expect(rejection["details"]).to eq(petition.rejection.details)
      end
    else
      expect(attributes["rejection"]).to be_nil
    end
  end

  def assert_serialized_government_response(petition, attributes)
    if petition.government_response?
      attributes["government_response"].tap do |government_response|
        expect(government_response["summary"]).to eq(petition.government_response.summary)
        expect(government_response["details"]).to eq(petition.government_response.details)
        expect(government_response["created_at"]).to eq(timestampify petition.government_response.created_at)
        expect(government_response["updated_at"]).to eq(timestampify petition.government_response.updated_at)
      end
    else
      expect(attributes["government_response"]).to be_nil
    end
  end

  def assert_serialized_debate(petition, attributes)
    if petition.debate_outcome?
      expect(attributes["debate"]).to be_a Hash
      attributes["debate"].tap do |debate|
        expect(debate["debated_on"]).to eq(datestampify petition.debate_outcome.debated_on)
        expect(debate["transcript_url"]).to eq(petition.debate_outcome.transcript_url)
        expect(debate["video_url"]).to eq(petition.debate_outcome.video_url)
        expect(debate["overview"]).to eq(petition.debate_outcome.overview)
      end
    else
      expect(attributes["debate"]).to be_nil
    end
  end


  def assert_serialized_petition(petition, serialized)
    # petition attributes
    expect(serialized["type"]).to eq("petition")
    expect(serialized["id"]).to eq(petition.id)

    expect(serialized["attributes"]).to be_a Hash
    serialized["attributes"].tap do |attributes|
      expect(attributes["action"]).to eq(petition.action)
      expect(attributes["background"]).to eq(petition.background)
      expect(attributes["additional_details"]).to eq(petition.additional_details)
      expect(attributes["state"]).to eq(petition.state)
      expect(attributes["signature_count"]).to eq(petition.cached_signature_count)

      # timestamps
      expect(attributes["created_at"]).to eq(timestampify petition.created_at)
      expect(attributes["updated_at"]).to eq(timestampify petition.cached_updated_at)
      expect(attributes["last_signed_at"]).to eq(timestampify petition.cached_last_signed_at)
      expect(attributes["open_at"]).to eq(timestampify petition.open_at)
      expect(attributes["closed_at"]).to eq(timestampify petition.closed_at)
      expect(attributes["government_response_at"]).to eq(timestampify petition.government_response_at)
      expect(attributes["scheduled_debate_date"]).to eq(timestampify petition.scheduled_debate_date)
      expect(attributes["response_threshold_reached_at"]).to eq(timestampify petition.response_threshold_reached_at)
      expect(attributes["debate_threshold_reached_at"]).to eq(timestampify petition.debate_threshold_reached_at)
      expect(attributes["rejected_at"]).to eq(timestampify petition.rejected_at)
      expect(attributes["debate_outcome_at"]).to eq(timestampify petition.debate_outcome_at)
      expect(attributes["moderation_threshold_reached_at"]).to eq(timestampify petition.moderation_threshold_reached_at)

      if petition.open?
        expect(attributes["creator_name"]).to eq(petition.creator_signature.name)
      end

      assert_serialized_rejection petition, attributes
      assert_serialized_government_response petition, attributes
      assert_serialized_debate petition, attributes
    end
  end
end
