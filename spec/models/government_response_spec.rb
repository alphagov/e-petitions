require 'rails_helper'

RSpec.describe GovernmentResponse, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:government_response)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:petition_id).of_type(:integer) }
    it { is_expected.to have_db_column(:summary).of_type(:string).with_options(limit: 500, null: false) }
    it { is_expected.to have_db_column(:details).of_type(:text) }
    it { is_expected.to have_db_column(:responded_on).of_type(:date) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]).unique }
  end

  describe "validations" do
    subject { FactoryBot.build(:government_response) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_presence_of(:summary) }
    it { is_expected.to validate_length_of(:summary).is_at_most(200) }
    it { is_expected.to validate_length_of(:details).is_at_most(6000) }
  end

  describe "callbacks" do
    context "when the government response is created" do
      let(:petition) { FactoryBot.create(:awaiting_response_petition) }
      let(:government_response) { FactoryBot.build(:government_response, petition: petition) }
      let(:now) { Time.current }

      it "updates the government_response_at timestamp" do
        expect {
          government_response.save!
        }.to change {
          petition.reload.government_response_at
        }.from(nil).to(be_within(1.second).of(now))
      end

      it "updates the response state" do
        expect {
          government_response.save!
        }.to change {
          petition.reload.response_state
        }.from("awaiting").to("responded")
      end
    end

    context "when the government response is deleted" do
      let(:government_response) { petition.government_response }

      context "and the petition has more than 10,000 signatures" do
        let(:petition) { FactoryBot.create(:responded_petition, government_response_at: 1.hour.ago, response_threshold_reached_at: 2.weeks.ago) }

        it "updates the government_response_at timestamp" do
          expect {
            government_response.destroy!
          }.to change {
            petition.reload.government_response_at
          }.from(be_within(1.second).of(1.hour.ago)).to(nil)
        end

        it "updates the response state" do
          expect {
            government_response.destroy!
          }.to change {
            petition.reload.response_state
          }.from("responded").to("awaiting")
        end
      end

      context "and the petition has less than 10,000 signatures" do
        let(:petition) { FactoryBot.create(:archived_petition, :response, government_response_at: 1.hour.ago, response_threshold_reached_at: nil) }

        it "updates the government_response_at timestamp" do
          expect {
            government_response.destroy!
          }.to change {
            petition.reload.government_response_at
          }.from(be_within(1.second).of(1.hour.ago)).to(nil)
        end

        it "updates the response state" do
          expect {
            government_response.destroy!
          }.to change {
            petition.reload.response_state
          }.from("responded").to("pending")
        end
      end
    end
  end
end
