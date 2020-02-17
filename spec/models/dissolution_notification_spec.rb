require 'rails_helper'

RSpec.describe DissolutionNotification, type: :model do
  let(:uuid) { "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6" }
  let(:email) { "alice@example.com" }

  subject { described_class.find(uuid) }

  before do
    described_class.create!(id: uuid)

    allow(Parliament).to receive(:dissolution_at).and_return(1.week.from_now)
  end

  it "has a valid factory" do
    expect(FactoryBot.build(:dissolution_notification)).to be_valid
  end

  describe "#petitions" do
    it "includes open petitions that I signed" do
      petition = FactoryBot.create(:open_petition)
      FactoryBot.create(:validated_signature, email: email, petition: petition)

      expect(subject.petitions).to include(petition)
    end

    it "includes open petitions that I sponsored" do
      petition = FactoryBot.create(:open_petition)
      FactoryBot.create(:validated_signature, email: email, sponsor: true, petition: petition)

      expect(subject.petitions).to include(petition)
    end

    it "includes open petitions that I signed just the once" do
      petition = FactoryBot.create(:open_petition)
      FactoryBot.create(:validated_signature, name: "Alice", email: email, petition: petition)
      FactoryBot.create(:validated_signature, name: "Angelica", email: email, petition: petition)

      expect(subject.petitions).to eq([petition])
    end

    it "is limited to the 5 most recent petitions" do
      petitions = 6.times.map do |n|
        FactoryBot.create(:open_petition, created_at: (6 - n).weeks.ago).tap do |petition|
          FactoryBot.create(:validated_signature, email: email, petition: petition)
        end
      end

      expect(subject.petitions).to eq(petitions[1..-1].reverse)
    end

    it "doesn't include open petitions I created" do
      petition = FactoryBot.create(:open_petition, creator_email: email)

      expect(subject.petitions).not_to include(petition)
    end

    it "doesn't include open petitions with a pending signature" do
      petition = FactoryBot.create(:open_petition)
      FactoryBot.create(:pending_signature, email: email, petition: petition)

      expect(subject.petitions).not_to include(petition)
    end

    it "doesn't include open petitions that I signed but have unsubscribed" do
      petition = FactoryBot.create(:open_petition)
      FactoryBot.create(:validated_signature, email: email, notify_by_email: false, petition: petition)

      expect(subject.petitions).not_to include(petition)
    end

    %w[pending validated sponsored flagged dormant rejected hidden closed].each do |state|
      it "doesn't include #{state} petitions" do
        petition = FactoryBot.create(:"#{state}_petition")
        FactoryBot.create(:validated_signature, email: email, petition: petition)

        expect(subject.petitions).not_to include(petition)
      end
    end
  end

  describe "#created_petitions" do
    it "includes open petitions that I created" do
      petition = FactoryBot.create(:open_petition, creator_email: email)

      expect(subject.created_petitions).to include(petition)
    end

    it "is limited to the 5 most recent petitions" do
      petitions = 6.times.map do |n|
        FactoryBot.create(:open_petition, creator_email: email, created_at: (6 - n).weeks.ago)
      end

      expect(subject.created_petitions).to eq(petitions[1..-1].reverse)
    end

    it "doesn't include open petitions that I sponsored" do
      petition = FactoryBot.create(:open_petition)
      FactoryBot.create(:validated_signature, email: email, sponsor: true, petition: petition)

      expect(subject.created_petitions).not_to include(petition)
    end

    it "doesn't include open petitions I signed" do
      petition = FactoryBot.create(:open_petition)
      FactoryBot.create(:validated_signature, email: email, petition: petition)

      expect(subject.created_petitions).not_to include(petition)
    end

    it "doesn't include open petitions that I created but have unsubscribed" do
      petition = FactoryBot.create(:open_petition, creator_attributes: { email: email, notify_by_email: false } )

      expect(subject.created_petitions).not_to include(petition)
    end

    %w[pending validated sponsored flagged dormant rejected hidden closed].each do |state|
      it "doesn't include #{state} petitions that I created" do
        petition = FactoryBot.create(:"#{state}_petition", creator_email: email)

        expect(subject.created_petitions).not_to include(petition)
      end
    end
  end

  describe "#remaining_petitions" do
    context "when there are less than 5 petitions" do
      before do
        2.times.map do |n|
          FactoryBot.create(:open_petition).tap do |petition|
            FactoryBot.create(:validated_signature, email: email, petition: petition)
          end
        end
      end


      it "returns the number of remaining petitions" do
        expect(subject.remaining_petitions).to be_zero
      end
    end

    context "when there are 5 petitions" do
      before do
        5.times.map do |n|
          FactoryBot.create(:open_petition).tap do |petition|
            FactoryBot.create(:validated_signature, email: email, petition: petition)
          end
        end
      end

      it "returns the number of remaining petitions" do
        expect(subject.remaining_petitions).to be_zero
      end
    end

    context "when there are more than 5 petitions" do
      before do
        7.times.map do |n|
          FactoryBot.create(:open_petition).tap do |petition|
            FactoryBot.create(:validated_signature, email: email, petition: petition)
          end
        end
      end

      it "returns the number of remaining petitions" do
        expect(subject.remaining_petitions).to eq(2)
      end
    end
  end

  describe "#remaining_created_petitions" do
    context "when there are less than 5 petitions" do
      before do
        2.times.map do |n|
          FactoryBot.create(:open_petition, creator_email: email)
        end
      end


      it "returns the number of remaining petitions" do
        expect(subject.remaining_created_petitions).to be_zero
      end
    end

    context "when there are 5 petitions" do
      before do
        5.times.map do |n|
          FactoryBot.create(:open_petition, creator_email: email)
        end
      end

      it "returns the number of remaining petitions" do
        expect(subject.remaining_created_petitions).to be_zero
      end
    end

    context "when there are more than 5 petitions" do
      before do
        7.times.map do |n|
          FactoryBot.create(:open_petition, creator_email: email)
        end
      end

      it "returns the number of remaining petitions" do
        expect(subject.remaining_created_petitions).to eq(2)
      end
    end
  end
end
