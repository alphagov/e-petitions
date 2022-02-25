require 'rails_helper'

RSpec.describe PrivacyNotification, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:privacy_notification)).to be_valid
  end

  describe "#petitions.sample" do
    let(:subject) { privacy_notification.petitions.sample }
    let(:ignore_petitions_before) { 1.year.ago }

    let(:privacy_notification) do
      FactoryBot.create(:privacy_notification, signature: signature)
    end

    context "validated signature" do
      let(:signature) do
        FactoryBot.create(:validated_signature)
      end

      Petition::MODERATED_STATES.each do |state|
        context "petition #{state}" do
          context "petition created before ignore_petitions_before date" do
            let!(:petition) do
              FactoryBot.create(
                "#{state}_petition",
                created_at: ignore_petitions_before - 1.day,
                signatures: [signature]
              )
            end

            it "does not include petition" do
              expect(subject).not_to include(petition)
            end
          end

          context "petition created after ignore_petitions_before date" do
            let!(:petition) do
              FactoryBot.create(
                "#{state}_petition",
                created_at: ignore_petitions_before + 1.day,
                signatures: [signature]
              )
            end

            it "does include petition" do
              expect(subject).to include(petition)
            end
          end
        end
      end

      (Petition::STATES - Petition::MODERATED_STATES).each do |state|
        context "petition #{state} and created after ignore_petitions_before date" do
          let!(:petition) do
            FactoryBot.create(
              "#{state}_petition",
              created_at: ignore_petitions_before + 1.day,
              signatures: [signature]
            )
          end

          it "does not include petition" do
            expect(subject).not_to include(petition)
          end
        end
      end
    end

    (Signature::STATES - [Signature::VALIDATED_STATE]).each do |state|
      context "signature #{state}, petition moderated and created after ignore_petitions_before date" do
        let(:signature) do
          FactoryBot.create("#{state}_signature")
        end

        let!(:petition) do
          FactoryBot.create(
            :open_petition,
            created_at: ignore_petitions_before + 1.day,
            signatures: [signature]
          )
        end

        it "does not include petition" do
          expect(subject).not_to include(petition)
        end
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
            created_at: ignore_petitions_before + (6 - n).days
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
        expect(subject).to eq(petitions.first(5))
      end
    end
  end

  describe "#petitions.remaining_count" do
    let(:subject) { privacy_notification.petitions.remaining_count }

    context "more than 5 petitions" do
      let(:privacy_notification) do
        FactoryBot.create(
          :privacy_notification,
          id:  "6613a3fd-c2c4-5bc2-a6de-3dc0b2527dd6"
        )
      end

      let!(:petitions) do
        6.times.map do
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
        expect(subject).to eq(1)
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
        3.times.map do
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
        expect(subject).to eq(0)
      end
    end
  end
end
