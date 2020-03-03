require 'rails_helper'

RSpec.describe DeletePetitionJob, type: :job do
  before do
    FactoryBot.create(:constituency, :london_and_westminster)
    FactoryBot.create(:location, code: "GB", name: "United Kingdom")
  end

  context "with a stopped petition" do
    let!(:petition) { FactoryBot.create(:stopped_petition) }

    it "destroys the petition" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Petition.count
      }.from(1).to(0)
    end
  end

  context "with a closed petition" do
    let!(:petition) { FactoryBot.create(:validated_petition, sponsors_signed: true, state: "closed", closed_at: 4.weeks.ago) }
    let!(:country_petition_journal) { FactoryBot.create(:country_petition_journal, petition: petition) }
    let!(:constituency_petition_journal) { FactoryBot.create(:constituency_petition_journal, petition: petition) }

    it "destroys the petition" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Petition.count
      }.from(1).to(0)
    end

    it "destroys the signatures" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Signature.count
      }.from(6).to(0)
    end

    it "destroys the country journals" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        CountryPetitionJournal.count
      }.from(1).to(0)
    end

    it "destroys the constituency journals" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        ConstituencyPetitionJournal.count
      }.from(1).to(0)
    end

    context "when the petition has a note" do
      before do
        FactoryBot.create(:note, petition: petition)
      end

      it "destroys the associated note" do
        expect {
          described_class.perform_now(petition)
        }.to change {
          Note.count
        }.from(1).to(0)
      end
    end

    context "when the petition has an email" do
      before do
        FactoryBot.create(:petition_email, petition: petition)
        FactoryBot.create(:email_requested_receipt, petition: petition)
      end

      it "destroys the associated email" do
        expect {
          described_class.perform_now(petition)
        }.to change {
          Petition::Email.count
        }.from(1).to(0)
      end

      it "destroys the associated email requested receipt" do
        expect {
          described_class.perform_now(petition)
        }.to change {
          EmailRequestedReceipt.count
        }.from(1).to(0)
      end
    end

    context "when the petition has a government response" do
      before do
        FactoryBot.create(:government_response, petition: petition)
      end

      it "destroys the associated government response" do
        expect {
          described_class.perform_now(petition)
        }.to change {
          GovernmentResponse.count
        }.from(1).to(0)
      end
    end

    context "when the petition has a debate outcome" do
      before do
        FactoryBot.create(:debate_outcome, petition: petition)
      end

      it "destroys the associated debate outcome" do
        expect {
          described_class.perform_now(petition)
        }.to change {
          DebateOutcome.count
        }.from(1).to(0)
      end
    end

    context "when the petition has an invalidation" do
      before do
        FactoryBot.create(:invalidation, petition: petition)
      end

      it "doesn't destroy the associated invalidation" do
        expect {
          described_class.perform_now(petition)
        }.not_to change {
          Invalidation.count
        }
      end
    end
  end

  context "with a rejected petition" do
    let!(:petition) { FactoryBot.create(:rejected_petition) }

    it "destroys the petition" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Petition.count
      }.from(1).to(0)
    end

    it "destroys the associated rejection" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Rejection.count
      }.from(1).to(0)
    end
  end

  context "with a hidden petition" do
    let!(:user) { FactoryBot.create(:moderator_user) }
    let!(:petition) { FactoryBot.create(:rejected_petition, rejection_code: "libellous", moderated_by: user) }

    it "destroys the petition" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Petition.count
      }.from(1).to(0)
    end

    it "destroys the associated rejection" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Rejection.count
      }.from(1).to(0)
    end
  end
end
