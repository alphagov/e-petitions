require 'rails_helper'
require 'digest/sha2'

RSpec.describe ArchivePetitionJob, type: :job do
  let(:petition) { FactoryBot.create(:closed_petition) }
  let(:archived_petition) { Archived::Petition.first }
  let(:email_request) { petition.email_requested_receipt }

  before do
    FactoryBot.create(:constituency, :coventry_north_east)
    FactoryBot.create(:constituency, :bethnal_green_and_bow)
    FactoryBot.create(:constituency_petition_journal, constituency_id: "3427", signature_count: 123, petition: petition)
    FactoryBot.create(:constituency_petition_journal, constituency_id: "3320", signature_count: 456, petition: petition)

    gb = FactoryBot.create(:location, code: "GB", name: "United Kingdom")
    us = FactoryBot.create(:location, code: "US", name: "United States")
    FactoryBot.create(:country_petition_journal, location: gb, signature_count: 1234, petition: petition)
    FactoryBot.create(:country_petition_journal, location: us, signature_count: 56, petition: petition)

    described_class.perform_now(petition)
  end

  it "enqueues an ArchiveSignaturesJob" do
    expect(ArchiveSignaturesJob).to have_been_enqueued.on_queue(:low_priority).with(petition, archived_petition)
  end

  context "with a closed petition" do
    let(:petition) do
      FactoryBot.create(
        :closed_petition,
        action: "Make Wombles Great Again",
        background: "The 70s was a great time for kids TV",
        additional_details: "Also the Clangers too",
        committee_note: "This petition action was found to be false",
        tags: tags.map(&:id),
        departments: departments.map(&:id),
        topics: topics.map(&:id),
        opened_at: 6.months.ago,
        closed_at: 2.months.ago,
        signature_count: 1234,
        do_not_anonymize: true,
        moderation_threshold_reached_at: 7.months.ago,
        moderation_lag: 30,
        last_signed_at: 3.months.ago,
        created_at: 8.months.ago,
        updated_at: 1.month.ago
      )
    end

    let(:departments) { FactoryBot.create_list(:department, 3) }
    let(:tags) { FactoryBot.create_list(:tag, 3) }
    let(:topics) { FactoryBot.create_list(:topic, 3) }

    let(:signatures_by_constituency) do
      archived_petition.read_attribute(:signatures_by_constituency)
    end

    let(:signatures_by_country) do
      archived_petition.read_attribute(:signatures_by_country)
    end

    it "copies the attributes" do
      expect(archived_petition.id).to eq(petition.id)
      expect(archived_petition.action).to eq(petition.action)
      expect(archived_petition.background).to eq(petition.background)
      expect(archived_petition.additional_details).to eq(petition.additional_details)
      expect(archived_petition.committee_note).to eq(petition.committee_note)
      expect(archived_petition.tags).to eq(petition.tags)
      expect(archived_petition.tags).not_to be_empty
      expect(archived_petition.departments).to eq(petition.departments)
      expect(archived_petition.departments).not_to be_empty
      expect(archived_petition.topics).to eq(petition.topics)
      expect(archived_petition.topics).not_to be_empty
      expect(archived_petition.state).to eq(petition.state)
      expect(archived_petition.opened_at).to be_usec_precise_with(petition.opened_at)
      expect(archived_petition.closed_at).to be_usec_precise_with(petition.closed_at)
      expect(archived_petition.signature_count).to eq(petition.signature_count)
      expect(archived_petition.do_not_anonymize).to eq(petition.do_not_anonymize)
      expect(archived_petition.moderation_threshold_reached_at).to be_usec_precise_with(petition.moderation_threshold_reached_at)
      expect(archived_petition.moderation_lag).to eq(petition.moderation_lag)
      expect(archived_petition.last_signed_at).to be_usec_precise_with(petition.last_signed_at)
      expect(archived_petition.created_at).to be_usec_precise_with(petition.created_at)
      expect(archived_petition.updated_at).to be_usec_precise_with(petition.updated_at)
    end

    it "copies the constituency_petition_journal data" do
      expect(signatures_by_constituency).to eq("3427" => 123, "3320" => 456)
    end

    it "copies the country_petition_journal data" do
      expect(signatures_by_country).to eq("GB" => 1234, "US" => 56)
    end
  end

  context "with a stopped petition" do
    let(:petition) do
      FactoryBot.create(:stopped_petition, stopped_at: 2.months.ago)
    end

    it "copies the attributes" do
      expect(archived_petition.stopped_at).to be_usec_precise_with(petition.stopped_at)
    end
  end

  context "with a petition marked for special consideration" do
    let(:petition) do
      FactoryBot.create(:stopped_petition, special_consideration: true)
    end

    it "copies the attributes" do
      expect(archived_petition.special_consideration).to eq(petition.special_consideration)
    end
  end

  context "with a petition that reached the response threshold" do
    let(:petition) do
      FactoryBot.create(:closed_petition, response_threshold_reached_at: 2.months.ago)
    end

    it "copies the attributes" do
      expect(archived_petition.response_threshold_reached_at).to be_usec_precise_with(petition.response_threshold_reached_at)
    end
  end

  context "with a petition that reached the debate threshold" do
    let(:petition) do
      FactoryBot.create(:closed_petition,
        debate_threshold_reached_at: 2.months.ago,
        debate_state: "awaiting"
      )
    end

    it "copies the attributes" do
      expect(archived_petition.debate_threshold_reached_at).to be_usec_precise_with(petition.debate_threshold_reached_at)
      expect(archived_petition.debate_state).to eq(petition.debate_state)
    end
  end

  context "with a petition that has a debate scheduled" do
    let(:petition) do
      FactoryBot.create(:closed_petition, scheduled_debate_date: 2.weeks.from_now)
    end

    it "copies the attributes" do
      expect(archived_petition.scheduled_debate_date).to eq(petition.scheduled_debate_date)
    end
  end

  context "with a rejected petition" do
    let(:petition) do
      FactoryBot.create(:rejected_petition,
        rejected_at: 6.months.ago,
        rejection_code: "irrelevant",
        rejection_details: "The government doesn't control kids TV"
      )
    end

    let(:rejection) { petition.rejection }
    let(:archived_rejection) { archived_petition.rejection }

    it "copies the attributes" do
      expect(archived_petition.rejected_at).to be_usec_precise_with(petition.rejected_at)
    end

    it "copies the rejection object" do
      expect(archived_rejection.code).to eq(rejection.code)
      expect(archived_rejection.details).to eq(rejection.details)
      expect(archived_rejection.created_at).to be_usec_precise_with(rejection.created_at)
      expect(archived_rejection.updated_at).to be_usec_precise_with(rejection.updated_at)
    end
  end

  context "with a responded petition" do
    let(:petition) do
      FactoryBot.create(:responded_petition,
        state: "closed",
        closed_at: 2.months.ago,
        government_response_at: 2.months.ago,
        response_summary: "Hell, yeah!",
        response_details: "We were kids too."
      )
    end

    let(:government_response) { petition.government_response }
    let(:archived_government_response) { archived_petition.government_response }

    it "copies the attributes" do
      expect(archived_petition.government_response_at).to be_usec_precise_with(petition.government_response_at)
    end

    it "copies the government_response object" do
      expect(archived_government_response.responded_on).to eq(government_response.responded_on)
      expect(archived_government_response.summary).to eq(government_response.summary)
      expect(archived_government_response.details).to eq(government_response.details)
      expect(archived_government_response.created_at).to be_usec_precise_with(government_response.created_at)
      expect(archived_government_response.updated_at).to be_usec_precise_with(government_response.updated_at)
    end
  end

  context "with a petition that has a debate outcome" do
    let(:debate_outcome) { petition.debate_outcome }
    let(:blob) { debate_outcome.image.blob }
    let(:archived_debate_outcome) { archived_petition.debate_outcome }
    let(:archived_blob) { archived_debate_outcome.image.blob }

    context "when the debate outcome doesn't have an image" do
      let(:petition) do
        FactoryBot.create(:debated_petition,
          state: "closed",
          closed_at: 2.months.ago,
          debate_outcome_at: 2.months.ago,
          debated_on: 2.months.ago,
          overview: "Debate on kids TV",
          transcript_url: "https://hansard.parliament.uk/commons/2017-04-24/debates/123456/KidsTV",
          video_url: "http://www.parliamentlive.tv/Event/Index/123456",
          debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2015-0001"
        )
      end

      it "copies the attributes" do
        expect(archived_petition.debate_outcome_at).to be_usec_precise_with(petition.debate_outcome_at)
      end

      it "copies the debate_outcome object" do
        expect(archived_debate_outcome.debated).to eq(debate_outcome.debated)
        expect(archived_debate_outcome.debated_on).to eq(debate_outcome.debated_on)
        expect(archived_debate_outcome.overview).to eq(debate_outcome.overview)
        expect(archived_debate_outcome.transcript_url).to eq(debate_outcome.transcript_url)
        expect(archived_debate_outcome.video_url).to eq(debate_outcome.video_url)
        expect(archived_debate_outcome.debate_pack_url).to eq(debate_outcome.debate_pack_url)
        expect(archived_debate_outcome.created_at).to be_usec_precise_with(debate_outcome.created_at)
        expect(archived_debate_outcome.updated_at).to be_usec_precise_with(debate_outcome.updated_at)
      end

      it "doesn't have an image" do
        expect(archived_debate_outcome.image).not_to be_attached
      end
    end

    context "when the debate outcome has an image" do
      let(:petition) do
        FactoryBot.create(:debated_petition,
          state: "closed",
          closed_at: 2.months.ago,
          debate_outcome_at: 2.months.ago,
          debated_on: 2.months.ago,
          overview: "Debate on kids TV",
          transcript_url: "https://hansard.parliament.uk/commons/2017-04-24/debates/123456/KidsTV",
          video_url: "http://www.parliamentlive.tv/Event/Index/123456",
          debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2015-0001",
          debate_image: fixture_file_upload("debate_outcome/commons_image-2x.jpg")
        )
      end

      it "copies the attributes" do
        expect(archived_petition.debate_outcome_at).to be_usec_precise_with(petition.debate_outcome_at)
      end

      it "copies the debate_outcome object" do
        expect(archived_debate_outcome.debated).to eq(debate_outcome.debated)
        expect(archived_debate_outcome.debated_on).to eq(debate_outcome.debated_on)
        expect(archived_debate_outcome.overview).to eq(debate_outcome.overview)
        expect(archived_debate_outcome.transcript_url).to eq(debate_outcome.transcript_url)
        expect(archived_debate_outcome.video_url).to eq(debate_outcome.video_url)
        expect(archived_debate_outcome.debate_pack_url).to eq(debate_outcome.debate_pack_url)
        expect(archived_debate_outcome.created_at).to be_usec_precise_with(debate_outcome.created_at)
        expect(archived_debate_outcome.updated_at).to be_usec_precise_with(debate_outcome.updated_at)
      end

      it "copies the image object data" do
        expect(archived_blob.id).not_to eq(blob.id)
        expect(archived_blob.filename).to eq(blob.filename)
        expect(archived_blob.content_type).to eq(blob.content_type)
        expect(archived_blob.byte_size).to eq(blob.byte_size)
        expect(archived_blob.checksum).to eq(blob.checksum)
      end
    end
  end

  context "with a petition that has an government_response email scheduled" do
    let(:petition) do
      FactoryBot.create(:closed_petition, :email_requested, email_requested_for_government_response_at: Time.current)
    end

    it "copies the receipt timestamp to the archived petition" do
      expect(archived_petition.email_requested_for_government_response_at).to be_usec_precise_with(email_request.government_response)
    end
  end

  context "with a petition that has an debate_scheduled email scheduled" do
    let(:petition) do
      FactoryBot.create(:closed_petition, :email_requested, email_requested_for_debate_scheduled_at: Time.current)
    end

    it "copies the receipt timestamp to the archived petition" do
      expect(archived_petition.email_requested_for_debate_scheduled_at).to be_usec_precise_with(email_request.debate_scheduled)
    end
  end

  context "with a petition that has an debate_outcome email scheduled" do
    let(:petition) do
      FactoryBot.create(:closed_petition, :email_requested, email_requested_for_debate_outcome_at: Time.current)
    end

    it "copies the receipt timestamp to the archived petition" do
      expect(archived_petition.email_requested_for_debate_outcome_at).to be_usec_precise_with(email_request.debate_outcome)
    end
  end

  context "with a petition that has an petition_email email scheduled" do
    let(:petition) do
      FactoryBot.create(:closed_petition, :email_requested, email_requested_for_petition_email_at: Time.current)
    end

    it "copies the receipt timestamp to the archived petition" do
      expect(archived_petition.email_requested_for_petition_email_at).to be_usec_precise_with(email_request.petition_email)
    end
  end
end
