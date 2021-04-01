require 'rails_helper'

RSpec.describe PaperPetition, type: :model do
  describe "validations" do
    %i[
      action_en background_en action_cy background_cy
      locale location_code signature_count submitted_on
      name email phone_number address postcode
    ].each do |attribute|
      it { is_expected.to validate_presence_of(attribute) }
    end

    [
      [%i[action_en action_cy], 100],
      [%i[background_en background_cy address], 500],
      [%i[additional_details_en additional_details_cy], 1100],
      [%i[email postcode], 255],
      [%i[phone_number], 31]
    ].each do |attributes, length|
      attributes.each do |attribute|
        it { is_expected.to validate_length_of(attribute).is_at_most(length) }
      end
    end

    %i[
      action_en background_en additional_details_en
      action_cy background_cy additional_details_cy
      name phone_number address
    ].each do |attribute|
      it { is_expected.not_to allow_value("-").for(attribute).with_message(:invalid) }
      it { is_expected.not_to allow_value("=").for(attribute).with_message(:invalid) }
      it { is_expected.not_to allow_value("+").for(attribute).with_message(:invalid) }
      it { is_expected.not_to allow_value("@").for(attribute).with_message(:invalid) }
    end

    it { is_expected.to allow_value("en-GB").for(:locale) }
    it { is_expected.to allow_value("cy-GB").for(:locale) }
    it { is_expected.not_to allow_value("en-US").for(:locale) }

    it { is_expected.to allow_value("alice@example.com").for(:email) }
    it { is_expected.not_to allow_value("alice").for(:email).with_message(:invalid) }

    it { is_expected.to allow_value("CF991NA").for(:postcode) }
    it { is_expected.not_to allow_value("CF99").for(:postcode).with_message(:invalid) }

    it { is_expected.to allow_value(50).for(:signature_count) }
    it { is_expected.not_to allow_value(49).for(:signature_count).with_message(:greater_than_or_equal_to) }
    it { is_expected.not_to allow_value(1.5).for(:signature_count).with_message(:greater_than_or_equal_to) }
    it { is_expected.not_to allow_value("one").for(:signature_count).with_message(:greater_than_or_equal_to) }
  end

  describe "#action_en=" do
    it "strips whitespace from the beginning and end" do
      subject.action_en = " Do stuff!  "
      expect(subject.action_en).to eq("Do stuff!")
    end
  end

  describe "#action_cy=" do
    it "strips whitespace from the beginning and end" do
      subject.action_cy = " Gwnewch bethau!  "
      expect(subject.action_cy).to eq("Gwnewch bethau!")
    end
  end

  describe "#background_en=" do
    it "strips whitespace from the beginning and end" do
      subject.background_en = " For reasons  "
      expect(subject.background_en).to eq("For reasons")
    end
  end

  describe "#background_cy=" do
    it "strips whitespace from the beginning and end" do
      subject.background_cy = " Am resymau  "
      expect(subject.background_cy).to eq("Am resymau")
    end
  end

  describe "#additional_details_en=" do
    it "strips whitespace from the beginning and end" do
      subject.additional_details_en = " Here's some more reasons  "
      expect(subject.additional_details_en).to eq("Here's some more reasons")
    end
  end

  describe "#additional_details_cy=" do
    it "strips whitespace from the beginning and end" do
      subject.additional_details_cy = " Dyma ychydig mwy o resymau  "
      expect(subject.additional_details_cy).to eq("Dyma ychydig mwy o resymau")
    end
  end

  describe "#additional_details_en?" do
    context "when additional_details_en has no content" do
      subject { described_class.new(additional_details_en: "") }

      it "returns false" do
        expect(subject.additional_details_en?).to eq(false)
      end
    end

    context "when additional_details_en has content" do
      subject { described_class.new(additional_details_en: "Here's some more reasons") }

      it "returns true" do
        expect(subject.additional_details_en?).to eq(true)
      end
    end
  end

  describe "#additional_details_cy?" do
    context "when additional_details_cy has no content" do
      subject { described_class.new(additional_details_cy: "") }

      it "returns false" do
        expect(subject.additional_details_cy?).to eq(false)
      end
    end

    context "when additional_details_cy has content" do
      subject { described_class.new(additional_details_cy: "Dyma ychydig mwy o resymau") }

      it "returns true" do
        expect(subject.additional_details_cy?).to eq(true)
      end
    end
  end

  describe "#name=" do
    it "strips whitespace from the beginning and end" do
      subject.name = " Bob Jones  "
      expect(subject.name).to eq("Bob Jones")
    end
  end

  describe "#email=" do
    it "strips whitespace from the beginning and end" do
      subject.email = " alice@example.com  "
      expect(subject.email).to eq("alice@example.com")
    end

    it "downcases the email address" do
      subject.email = "Alice@Example.com"
      expect(subject.email).to eq("alice@example.com")
    end
  end

  describe "#phone_number=" do
    it "strips whitespace from the beginning and end" do
      subject.phone_number = " 024 1234 5678  "
      expect(subject.phone_number).to eq("024 1234 5678")
    end
  end

  describe "#save" do
    subject { described_class.new(params) }

    context "when the params are invalid" do
      let(:params) { Hash.new }

      it "returns false" do
        expect(subject.save).to eq(false)
      end
    end

    context "when the params are valid" do
      let(:params) do
        {
          action_en: "Do stuff!", action_cy: "Gwnewch bethau!",
          background_en: "For reasons", background_cy: "Am resymau",
          additional_details_en: "Here's some more reasons",
          additional_details_cy: "Dyma ychydig mwy o resymau",
          locale: "cy-GB", signature_count: 6000, submitted_on: "2020-04-30",
          name: "Alice Smith", email: "alice@example.com", postcode: "CF99 1NA",
          address: "The Senedd\nPierhead St\nCardiff", phone_number: "0300 200 6565"
        }
      end

      let(:petition) { subject.petition }
      let(:signature) { petition.creator }
      let(:contact) { signature.contact }

      it "returns true" do
        expect(subject.save).to eq(true)

        expect(petition).to have_attributes(
          state: "closed",
          submitted_on_paper: true,
          submitted_on: Date.civil(2020, 4, 30),
          action_en: "Do stuff!",
          action_cy: "Gwnewch bethau!",
          background_en: "For reasons",
          background_cy: "Am resymau",
          additional_details_en: "Here's some more reasons",
          additional_details_cy: "Dyma ychydig mwy o resymau",
          locale: "cy-GB", signature_count: 6000,
          open_at: Time.utc(2020, 3, 1, 12, 0, 0),
          closed_at: Time.utc(2020, 4, 30, 11, 0, 0),
          moderation_threshold_reached_at: Time.utc(2020, 4, 30, 11, 0, 0),
          referral_threshold_reached_at: Time.utc(2020, 4, 30, 11, 0, 0),
          debate_threshold_reached_at: Time.utc(2020, 4, 30, 11, 0, 0),
          last_signed_at: Time.utc(2020, 4, 30, 11, 0, 0),
          referred_at: Time.utc(2020, 4, 30, 11, 0, 0),
        )

        expect(signature).to have_attributes(
          state: "pending",
          name: "Alice Smith",
          email: "alice@example.com",
          postcode: "CF991NA",
          location_code: "GB-WLS",
          locale: "cy-GB"
        )

        expect(contact).to have_attributes(
          address: "The Senedd\nPierhead St\nCardiff",
          phone_number: "0300 200 6565"
        )
      end
    end
  end
end
