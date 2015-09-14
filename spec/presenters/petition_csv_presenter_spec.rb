require 'rails_helper'

RSpec.describe PetitionCSVPresenter do
  include TimestampsSpecHelper

  describe "#initialize" do
    it "initializes the presenter with a petition" do
      presenter = described_class.new("foo")
      expect(presenter.petition).to eq("foo")
    end
  end

  describe ".fields" do
    it "returns a list of all the fields to serialize" do
      expect(described_class.fields).to be_a Array
    end
  end

  describe "#to_csv" do
    subject { described_class.new(petition).to_csv }

    Petition::STATES.each do |state_name|
      context "with a #{state_name} petition" do
        let!(:petition) { FactoryGirl.create "#{state_name}_petition" }

        specify { is_expected.to eq(csvd_petition petition) }
      end
    end
  end

  def csvd_petition(petition)
    [
      "#{Site.send :default_url}/petitions/#{petition.id}",
      "#{Site.send :default_moderate_url}/admin/petitions/#{petition.id}",
      petition.id,
      petition.action,
      petition.background,
      petition.additional_details,
      petition.state,
      petition.creator_name,
      petition.creator_email,
      petition.signature_count,
      petition.rejection_code,
      petition.rejection_details,
      petition.government_response_summary,
      petition.government_response_details,
      petition.debate_date,
      petition.debate_transcript_url,
      petition.debate_video_url,
      petition.debate_overview,
      timestampify(petition.created_at),
      timestampify(petition.updated_at),
      timestampify(petition.open_at),
      timestampify(petition.closed_at),
      timestampify(petition.government_response_at),
      datestampify(petition.scheduled_debate_date),
      timestampify(petition.response_threshold_reached_at),
      timestampify(petition.debate_threshold_reached_at),
      timestampify(petition.rejected_at),
      timestampify(petition.debate_outcome_at),
      timestampify(petition.moderation_threshold_reached_at),
      timestampify(petition.government_response_created_at),
      timestampify(petition.government_response_updated_at),
      petition.note.try(:details)
    ].join(",") + "\n"
  end
end
