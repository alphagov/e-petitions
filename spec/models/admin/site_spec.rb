require 'rails_helper'

RSpec.describe Admin::Site, type: :model do
  describe "#petition_tags=" do
    subject do
      described_class.new(petition_tags: " Tag 1\r\nTag 2\r\n")
    end

    it "normalizes line endings and strips whitespace" do
      expect(subject.petition_tags).to eq("Tag 1\nTag 2")
    end
  end

  describe "#allowed_petitions_tags" do
    subject do
      described_class.create!(petition_tags: allowed_petition_tags)
    end

    let(:tag_1) { "Tag 1" }
    let(:tag_2) { "Tag 2" }

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
