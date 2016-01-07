require 'rails_helper'

RSpec.describe DebateOutcome, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:debate_outcome)).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:petition).touch(true) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id]).unique }
    it { is_expected.to have_db_index([:petition_id, :debated_on]) }
  end

  describe "validations" do
    subject { FactoryGirl.build(:debate_outcome) }

    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_length_of(:transcript_url).is_at_most(500) }
    it { is_expected.to validate_length_of(:video_url).is_at_most(500) }

    context "when then petition was debated" do
      subject { described_class.new(debated: true) }

      it { is_expected.to validate_presence_of(:debated_on) }
    end

    context "when then petition was not debated" do
      subject { described_class.new(debated: false) }

      it { is_expected.not_to validate_presence_of(:debated_on) }
    end

  end

  describe "commons_image" do
    let(:petition) { FactoryGirl.create(:awaiting_debate_petition) }
    let(:debate_outcome) { FactoryGirl.build(:debate_outcome, petition: petition) }

    it { should have_attached_file(:commons_image) }

    describe "validation" do
      it { should validate_attachment_content_type(:commons_image).
                allowing("image/png", "image/gif", "image/jpeg").
                rejecting("text/plain", "text/xml") }
    end

    context "with a valid file" do
      before { debate_outcome.commons_image = File.open(commons_image_file) }
      it "is valid" do
        expect(debate_outcome.valid?).to be true
      end
    end

    context "with a too-small file" do
      before do
        debate_outcome.commons_image = File.open(commons_image_file_too_small)
        debate_outcome.valid?
      end

      it "is invalid" do
        expect(debate_outcome.valid?).to be false
      end

      it "contains the correct error" do
        expect(debate_outcome.errors).to include(:commons_image)
        expect(debate_outcome.errors[:commons_image].size).to eq 2
        expect(debate_outcome.errors[:commons_image]).to include("Width must be at least 1260.0px (is 500.0px)")
        expect(debate_outcome.errors[:commons_image]).to include("Height must be 709.0px (is 281.0px)")
      end
    end

    context "with a file of of the wrong ratio" do
      before do
        debate_outcome.commons_image = File.open(commons_image_file_wrong_ratio)
        debate_outcome.valid?
      end

      it "is invalid" do
        expect(debate_outcome.valid?).to be false
      end

      it "contains the correct error" do
        expect(debate_outcome.errors).to include(:commons_image)
        expect(debate_outcome.errors[:commons_image].size).to eq 2
        expect(debate_outcome.errors[:commons_image]).to include("Width must be at least 1260.0px (is 709.0px)")
        expect(debate_outcome.errors[:commons_image]).to include("Width and height ratio of uploaded image is 0.56 - should be between 1.68 and 1.88")
      end
    end
  end

  describe "callbacks" do
    describe "when the debate outcome is created" do
      let(:petition) { FactoryGirl.create(:awaiting_debate_petition) }
      let(:debate_outcome) { FactoryGirl.build(:debate_outcome, petition: petition) }
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
      let(:petition) { FactoryGirl.create(:awaiting_debate_petition) }
      let(:debate_outcome) { FactoryGirl.build(:debate_outcome, petition: petition) }

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
        }.from("debated").to("none")
      end
    end
  end
end
