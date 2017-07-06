require 'rails_helper'

RSpec.describe Admin::Settings, type: :model do
  describe "validations" do
    describe "checking existing petitions for deleted tags" do
      let!(:settings) { described_class.create(petition_tags: "tag 1\ntag 2\ntag 3") }
      let!(:petition_a) { FactoryGirl.create(:open_petition, tags: ["tag 1", "tag 2"]) }
      let!(:petition_b) { FactoryGirl.create(:open_petition, tags: ["tag 2", "tag 3"]) }
      let!(:petition_c) { FactoryGirl.create(:open_petition, tags: ["tag 3"]) }
      let(:error_message_for_tag_1) do
        "Tag 'tag 1' still being used on petitions: #{petition_a.id}"
      end
      let(:error_message_for_tag_2) do
        "Tag 'tag 2' still being used on petitions: #{petition_a.id}, #{petition_b.id}"
      end

      it "checks for petitions with deleted tags if petition_tags have changed" do
        settings.petition_tags = "tag 3\ntag 4"
        expect(settings).to receive(:no_petitions_have_deleted_tags)
        settings.save
      end

      it "does not check for petitions with deleted tags if petition_tags have not changed" do
        settings.petition_tags = "tag 1\ntag 2\ntag 3"
        expect(settings).not_to receive(:no_petitions_have_deleted_tags)
        settings.save
      end

      it "adds an error message with all petition ids that are still using deleted tags" do
        settings.petition_tags = "tag 3\ntag 4"
        settings.save
        expect(settings.errors[:petition_tags].size).to eq 2
        expect(settings.errors[:petition_tags]).to include error_message_for_tag_1
        expect(settings.errors[:petition_tags]).to include error_message_for_tag_2
      end
    end

    context "when there duplicate tags" do
      let(:admin_settings) { described_class.create(petition_tags: tags) }
      let(:tags) { "tag 1\ntag 1" }

      it "is invalid" do
        expect(admin_settings).to be_invalid
        expect(admin_settings.errors[:petition_tags]).to include "Duplicate tags not allowed: tag 1"
      end

      context "that are in a different case" do
        let(:tags) { "tag 1\nTAG 1"}

        it "is invalid" do
          expect(admin_settings).to be_invalid
          expect(admin_settings.errors[:petition_tags]).to include "Duplicate tags not allowed: tag 1"
        end
      end
    end
  end

  describe "#petition_tags=" do
    subject do
      described_class.new(petition_tags: " Tag 1\r\nTag 2\r\n")
    end

    it "normalizes line endings, downcases and strips whitespace" do
      expect(subject.petition_tags).to eq("tag 1\ntag 2")
    end
  end

  describe "#allowed_petitions_tags" do
    subject do
      described_class.create!(petition_tags: allowed_petition_tags)
    end

    let(:tag_1) { "tag 1" }
    let(:tag_2) { "tag 2" }

    context "when there is extra whitespace" do
      let :allowed_petition_tags do
        <<-EOF
          Tag 1
             Tag 2

        EOF
      end

      it "is is stripped" do
        expect(subject.allowed_petition_tags).to eq([tag_1, tag_2])
      end
    end

    context "when there are blank lines" do
      let :allowed_petition_tags do
        <<-EOF
          Tag 1

             Tag 2

        EOF
      end

      it "they are stripped" do
        expect(subject.allowed_petition_tags).to eq([tag_1, tag_2])
      end
    end

    context "when there are line comments" do
      let :allowed_petition_tags do
        <<-EOF
          # This is a test
          Tag 1

             Tag 2

        EOF
      end

      it "they are stripped" do
        expect(subject.allowed_petition_tags).to eq([tag_1, tag_2])
      end
    end

    context "when there are inline comments" do
      let :allowed_petition_tags do
        <<-EOF
          Tag 1 # This is a test

             Tag 2

        EOF
      end

      it "they are stripped" do
        expect(subject.allowed_petition_tags).to eq([tag_1, tag_2])
      end
    end
  end
end
