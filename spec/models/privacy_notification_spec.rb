require 'rails_helper'

RSpec.describe PrivacyNotification, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:privacy_notification)).to be_valid
  end

  describe "#petitions" do
    Petition::MODERATED_STATES.each do |state|
      context "signature validated, petition #{state} and not anonymized" do
        let(:petition) { FactoryBot.create("#{state}_petition") }

        let(:signature) do
          FactoryBot.create(:validated_signature, petition: petition)
        end

        let(:privacy_notification) do
          FactoryBot.create(:privacy_notification, signature: signature)
        end

        it "includes petition" do
          expect(privacy_notification.petitions).to include(petition)
        end
      end
    end

    (Petition::STATES - Petition::MODERATED_STATES).each do |state|
      context "signature validated, petition #{state} and not anonymized" do
        let(:petition) { FactoryBot.create("#{state}_petition") }

        let(:signature) do
          FactoryBot.create(:validated_signature, petition: petition)
        end

        let(:privacy_notification) do
          FactoryBot.create(:privacy_notification, signature: signature)
        end

        it "does not include petition" do
          expect(privacy_notification.petitions).not_to include(petition)
        end
      end
    end

    (Signature::STATES - [Signature::VALIDATED_STATE]).each do |state|
      context "signature #{state}, petition moderated and not anonymized" do
        let(:petition) { FactoryBot.create(:open_petition) }

        let(:signature) do
          FactoryBot.create("#{state}_signature".to_sym, petition: petition)
        end

        let(:privacy_notification) do
          FactoryBot.create(:privacy_notification, signature: signature)
        end

        it "does not include petition" do
          expect(privacy_notification.petitions).not_to include(petition)
        end
      end
    end

    context "signature validated, petition moderated and anonymized" do
      let(:petition) do
        FactoryBot.create(:open_petition, anonymized_at: DateTime.current)
      end

      let(:signature) do
        FactoryBot.create(:validated_signature, petition: petition)
      end

      let!(:privacy_notification) do
        FactoryBot.create(:privacy_notification, signature: signature)
      end

      it "does not include petition" do
        expect(privacy_notification.petitions).not_to include(petition)
      end
    end

    context "more than 5 petitions" do
      let(:privacy_notification) do
        FactoryBot.create(
          :privacy_notification,
          id:  "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6"
        )
      end

      let!(:petitions) do
        6.times.map do |n|
          petition = FactoryBot.create(
            :open_petition,
            created_at: (6 - n).weeks.ago
          )

          petition.tap do |petition|
            FactoryBot.create(
              :validated_signature,
              email: "alice@example.com",
              petition: petition
            )
          end
        end
      end

      it "only returns the 5 most recent petitions" do
        expect(privacy_notification.petitions).to eq(petitions[1..-1].reverse)
      end
    end
  end

  describe "#remaining_petition_count" do
    context "more than 5 petitions" do
      let(:privacy_notification) do
        FactoryBot.create(
          :privacy_notification,
          id:  "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6"
        )
      end

      let!(:petitions) do
        6.times.map do |n|
          petition = FactoryBot.create(:open_petition)

          petition.tap do |petition|
            FactoryBot.create(
              :validated_signature,
              email: "alice@example.com",
              petition: petition
            )
          end
        end
      end

      it "returns the number of remaining petitions" do
        expect(privacy_notification.remaining_petition_count).to eq(1)
      end
    end

    context "less than 5 petitions" do
      let(:privacy_notification) do
        FactoryBot.create(
          :privacy_notification,
          id:  "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6"
        )
      end

      let!(:petitions) do
        3.times.map do |n|
          petition = FactoryBot.create(:open_petition)

          petition.tap do |petition|
            FactoryBot.create(
              :validated_signature,
              email: "alice@example.com",
              petition: petition
            )
          end
        end
      end

      it "returns zero" do
        expect(privacy_notification.remaining_petition_count).to eq(0)
      end
    end
  end
end
