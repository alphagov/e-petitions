require 'rails_helper'

RSpec.describe DeletePetitionJob, type: :job do
  context "with a stopped petition" do
    let!(:petition) { FactoryGirl.create(:stopped_petition) }

    it "destroys the petition" do
      expect {
        described_class.perform_now(petition)
      }.to change {
        Petition.count
      }.from(1).to(0)
    end
  end

  context "with a closed petition" do
    let!(:petition) { FactoryGirl.create(:validated_petition, sponsors_signed: true, state: "closed", closed_at: 4.weeks.ago) }
    let!(:country_petition_journal) { FactoryGirl.create(:country_petition_journal, petition: petition) }
    let!(:constituency_petition_journal) { FactoryGirl.create(:constituency_petition_journal, petition: petition) }

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
        FactoryGirl.create(:note, petition: petition)
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
        FactoryGirl.create(:petition_email, petition: petition)
        FactoryGirl.create(:email_requested_receipt, petition: petition)
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
        FactoryGirl.create(:government_response, petition: petition)
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
        FactoryGirl.create(:debate_outcome, petition: petition)
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
        FactoryGirl.create(:invalidation, petition: petition)
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
    let!(:petition) { FactoryGirl.create(:rejected_petition) }

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
    let!(:petition) { FactoryGirl.create(:rejected_petition, rejection_code: "libellous") }

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
