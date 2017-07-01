require 'rails_helper'

RSpec.describe ArchiveSignaturesJob, type: :job do
  let(:petition) { FactoryGirl.create(:validated_petition, sponsors_signed: true) }
  let(:archived_petition) { FactoryGirl.create(:archived_petition) }
  let(:archived_signature) { archived_petition.signatures.last }

  it "copies every signature" do
    expect {
      described_class.perform_now(petition, archived_petition)
    }.to change {
      archived_petition.signatures.count
    }.from(0).to(6)
  end

  context "with the creator signature" do
    let(:signature) { archived_petition.signatures.first }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it "assigns the creator attribute" do
      expect(signature).to be_creator
    end
  end

  context "with a sponsor signature" do
    let(:signature) { archived_petition.signatures.second }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it "assigns the sponsor attribute" do
      expect(signature).to be_sponsor
    end
  end

  shared_examples_for "a copied signature" do
    it "copies the attributes of the signature" do
      expect(archived_signature.uuid).to eq(signature.uuid)
      expect(archived_signature.state).to eq(signature.state)
      expect(archived_signature.number).to eq(signature.number)
      expect(archived_signature.name).to eq(signature.name)
      expect(archived_signature.email).to eq(signature.email)
      expect(archived_signature.postcode).to eq(signature.postcode)
      expect(archived_signature.location_code).to eq(signature.location_code)
      expect(archived_signature.constituency_id).to eq(signature.constituency_id)
      expect(archived_signature.ip_address).to eq(signature.ip_address)
      expect(archived_signature.perishable_token).to eq(signature.perishable_token)
      expect(archived_signature.unsubscribe_token).to eq(signature.unsubscribe_token)
      expect(archived_signature.notify_by_email).to eq(signature.notify_by_email)
      expect(archived_signature.created_at).to be_usec_precise_with(signature.created_at)
      expect(archived_signature.updated_at).to be_usec_precise_with(signature.updated_at)
    end

    it "is persisted" do
      expect(archived_signature.persisted?).to eq(true)
    end
  end

  context "with a pending signature" do
    let!(:signature) { FactoryGirl.create(:pending_signature, petition: petition) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"
  end

  context "with a validated signature" do
    let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, number: 7) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"

    it "copies the validated_at timestamp" do
      expect(archived_signature.validated_at).to be_usec_precise_with(signature.validated_at)
    end
  end

  context "with an invalidated signature" do
    let!(:invalidation) { FactoryGirl.create(:invalidation, name: "Jo Public") }
    let!(:signature) { FactoryGirl.create(:invalidated_signature, petition: petition, invalidation: invalidation) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"

    it "copies the invalidation assocation" do
      expect(archived_signature.invalidation_id).to be_usec_precise_with(signature.invalidation_id)
    end

    it "copies the invalidated_at timestamp" do
      expect(archived_signature.invalidated_at).to be_usec_precise_with(signature.invalidated_at)
    end
  end

  context "with a fradulent signature" do
    let!(:signature) { FactoryGirl.create(:fraudulent_signature, petition: petition) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"
  end

  context "with a signature that has been notified about a government response" do
    let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, government_response_email_at: 4.weeks.ago) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"

    it "copies the government_response_email_at timestamp" do
      expect(archived_signature.government_response_email_at).to be_usec_precise_with(signature.government_response_email_at)
    end
  end

  context "with a signature that has been notified about a scheduled debate" do
    let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, debate_scheduled_email_at: 4.weeks.ago) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"

    it "copies the debate_scheduled_email_at timestamp" do
      expect(archived_signature.debate_scheduled_email_at).to be_usec_precise_with(signature.debate_scheduled_email_at)
    end
  end

  context "with a signature that has been notified about a debate outcome" do
    let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, debate_outcome_email_at: 4.weeks.ago) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"

    it "copies the debate_outcome_email_at timestamp" do
      expect(archived_signature.debate_outcome_email_at).to be_usec_precise_with(signature.debate_outcome_email_at)
    end
  end

  context "with a signature that has been notified about a other business" do
    let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition, petition_email_at: 4.weeks.ago) }

    before do
      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"

    it "copies the petition_email_at timestamp" do
      expect(archived_signature.petition_email_at).to be_usec_precise_with(signature.petition_email_at)
    end
  end

  context "with a signature that has invalid attributes" do
    let!(:signature) { FactoryGirl.create(:validated_signature, petition: petition) }

    before do
      signature.update_column(:location_code, nil)
      signature.reload

      described_class.perform_now(petition, archived_petition)
    end

    it_behaves_like "a copied signature"

    it "the original signature is invalid" do
      expect(signature.valid?).to eq(false)
    end

    it "the archived signature is invalid" do
      expect(signature.valid?).to eq(false)
    end
  end

  context "when there are no signatures left" do
    it "marks the petition as archived" do
      expect {
        described_class.perform_now(petition, archived_petition)
      }.to change {
        petition.reload.archived_at
      }.from(nil).to(be_within(1.second).of(Time.current))
    end

    it "doesn't enqueue a new job" do
      expect {
        described_class.perform_now(petition, archived_petition)
      }.not_to change {
        enqueued_jobs
      }
    end
  end

  context "when there are signatures left" do
    it "doesn't mark the petition as archived" do
      expect {
        described_class.perform_now(petition, archived_petition, 0, limit: 2)
      }.not_to change {
        petition.reload.archived_at
      }
    end

    it "enqueues another ArchiveSignaturesJob job" do
      archive_signatures_job = {
        job: ArchiveSignaturesJob,
        args: [
          { "_aj_globalid" => "gid://epets/Petition/#{petition.id}" },
          { "_aj_globalid" => "gid://epets/Archived::Petition/#{archived_petition.id}" },
          petition.signatures.second.id + 1,
          { "limit" => 2, "_aj_symbol_keys" => ["limit"] }
        ],
        queue: "high_priority"
      }

      expect {
        described_class.perform_now(petition, archived_petition, 0, limit: 2)
      }.to change {
        enqueued_jobs
      }.from([]).to([archive_signatures_job])
    end
  end
end
