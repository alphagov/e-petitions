require 'rails_helper'

RSpec.describe DebateOutcome, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:debate_outcome)).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]).unique }
    it { is_expected.to have_db_index([:petition_id, :debated_on]) }
  end

  describe "validations" do
    subject { FactoryBot.build(:debate_outcome) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_length_of(:transcript_url_en).is_at_most(500) }
    it { is_expected.to validate_length_of(:video_url_en).is_at_most(500) }
    it { is_expected.to validate_length_of(:debate_pack_url_en).is_at_most(500) }
    it { is_expected.to validate_length_of(:transcript_url_cy).is_at_most(500) }
    it { is_expected.to validate_length_of(:video_url_cy).is_at_most(500) }
    it { is_expected.to validate_length_of(:debate_pack_url_cy).is_at_most(500) }

    it { is_expected.to allow_value("https://www.example.com/").for(:debate_pack_url_en) }
    it { is_expected.to allow_value("https://www.example.com/").for(:debate_pack_url_cy) }
    it { is_expected.to allow_value("https://www.example.com/").for(:transcript_url_en) }
    it { is_expected.to allow_value("https://www.example.com/").for(:transcript_url_cy) }
    it { is_expected.to allow_value("https://www.example.com/").for(:video_url_en) }
    it { is_expected.to allow_value("https://www.example.com/").for(:video_url_cy) }

    it { is_expected.to allow_value("http://www.example.com/").for(:debate_pack_url_en) }
    it { is_expected.to allow_value("http://www.example.com/").for(:debate_pack_url_cy) }
    it { is_expected.to allow_value("http://www.example.com/").for(:transcript_url_en) }
    it { is_expected.to allow_value("http://www.example.com/").for(:transcript_url_cy) }
    it { is_expected.to allow_value("http://www.example.com/").for(:video_url_en) }
    it { is_expected.to allow_value("http://www.example.com/").for(:video_url_cy) }

    it { is_expected.not_to allow_value("javascript:alert('Hello, World!');").for(:debate_pack_url_en) }
    it { is_expected.not_to allow_value("javascript:alert('Hello, World!');").for(:debate_pack_url_cy) }
    it { is_expected.not_to allow_value("javascript:alert('Hello, World!');").for(:transcript_url_en) }
    it { is_expected.not_to allow_value("javascript:alert('Hello, World!');").for(:transcript_url_cy) }
    it { is_expected.not_to allow_value("javascript:alert('Hello, World!');").for(:video_url_en) }
    it { is_expected.not_to allow_value("javascript:alert('Hello, World!');").for(:video_url_cy) }

    context "when then petition was debated" do
      subject { described_class.new(debated: true) }

      it { is_expected.to validate_presence_of(:debated_on) }
    end

    context "when then petition was not debated" do
      subject { described_class.new(debated: false) }

      it { is_expected.not_to validate_presence_of(:debated_on) }
    end

  end

  describe "image" do
    let(:petition) { FactoryBot.create(:awaiting_debate_petition) }
    let(:debate_outcome) { FactoryBot.build(:debate_outcome, petition: petition) }

    it { is_expected.to have_one_attached(:image) }

    describe "validations" do
      let(:non_image) { fixture_file_upload("debate_outcome/commons_image-2x.txt") }
      let(:non_jpeg) { fixture_file_upload("debate_outcome/commons_image-2x.png") }
      let(:too_large) { fixture_file_upload("debate_outcome/commons_image-3x.jpg") }
      let(:too_narrow) { fixture_file_upload("debate_outcome/commons_image-too-narrow.jpg") }
      let(:too_wide) { fixture_file_upload("debate_outcome/commons_image-too-wide.jpg") }
      let(:too_short) { fixture_file_upload("debate_outcome/commons_image-too-short.jpg") }
      let(:too_tall) { fixture_file_upload("debate_outcome/commons_image-too-tall.jpg") }
      let(:incorrect_ratio) { fixture_file_upload("debate_outcome/commons_image-incorrect-ratio.jpg") }

      it { is_expected.not_to allow_value(non_image).for(:image).with_message("Incorrect file type - please select a JPEG image") }
      it { is_expected.not_to allow_value(non_jpeg).for(:image).with_message("Incorrect file type - please select a JPEG image") }
      it { is_expected.not_to allow_value(too_large).for(:image).with_message("The image is too large (maximum is 512 KB)") }
      it { is_expected.not_to allow_value(too_narrow).for(:image).with_message("Width must be at least 648px (is 512px)") }
      it { is_expected.not_to allow_value(too_wide).for(:image).with_message("Width must be at most 1800px (is 2000px)") }
      it { is_expected.not_to allow_value(too_short).for(:image).with_message("Height must be at least 365px (is 300px)") }
      it { is_expected.not_to allow_value(too_tall).for(:image).with_message("Height must be at most 1200px (is 1300px)") }
      it { is_expected.not_to allow_value(incorrect_ratio).for(:image).with_message("Aspect ratio of the image is 1 - should be between 1.5 and 1.8") }
    end
  end

  describe "callbacks" do
    describe "when the debate outcome is created" do
      let(:petition) { FactoryBot.create(:awaiting_debate_petition) }
      let(:debate_outcome) { FactoryBot.build(:debate_outcome, petition: petition) }
      let(:now) { Time.current }

      it "updates the debate_outcome_at timestamp" do
        expect {
          debate_outcome.save!
        }.to change {
          petition.reload.debate_outcome_at
        }.from(nil).to(be_within(1.second).of(now))
      end

      it "updates the debate state" do
        expect {
          debate_outcome.save!
        }.to change {
          petition.reload.debate_state
        }.from("awaiting").to("debated")
      end
    end

    describe "when the debate outcome is updated" do
      let(:petition) { FactoryBot.create(:awaiting_debate_petition) }
      let(:debate_outcome) { FactoryBot.build(:debate_outcome, petition: petition) }

      before do
        travel_to 2.days.ago do
          debate_outcome.save!
        end
      end

      it "does not update the debate_outcome_at timestamp" do
        expect {
          debate_outcome.update!(debated: false)
        }.not_to change {
          petition.reload.debate_outcome_at
        }
      end

      it "updates the debate state" do
        expect {
          debate_outcome.update!(debated: false)
        }.to change {
          petition.reload.debate_state
        }.from("debated").to("not_debated")
      end
    end
  end
end
