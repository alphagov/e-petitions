require 'rails_helper'

RSpec.describe PetitionSignedDataUpdateJob, type: :job do
  let(:signature) { FactoryGirl.create(:pending_signature, petition: petition, created_at: 2.days.ago, updated_at: 2.days.ago) }

  def running_the_job
    perform_enqueued_jobs {
      described_class.perform_later(signature)
    }
  end
  alias_method :run_the_job, :running_the_job

  context 'when the signature has gone away' do
    let(:petition) { FactoryGirl.create(:open_petition, created_at: 2.days.ago, updated_at: 2.days.ago) }

    before do
      Signature.delete(signature)
    end

    it 'notifies appsignal of the deserialization problem' do
      expect(Appsignal).to receive(:send_exception).with(an_instance_of(ActiveJob::DeserializationError))
      run_the_job
    end

    it 'does not raise the deserialization problem (which would cause the worker to requeue the job)' do
      expect { running_the_job }.not_to raise_error
    end
  end

  context "when the petition is open" do
    let(:petition) { FactoryGirl.create(:open_petition, created_at: 2.days.ago, updated_at: 2.days.ago) }

    it "increments the petition count" do
      expect{ running_the_job }.to change{ petition.reload.signature_count }.by(1)
    end

    it "updates the petition to say it was updated just now" do
      expect{ running_the_job }.to change { petition.reload.updated_at }
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    it "updates the petition to say it was last signed at just now" do
      expect{ running_the_job }.to change { petition.reload.last_signed_at }
      expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
    end

    it 'tells the relevant constituency petition journal to record a new signature' do
      expect(ConstituencyPetitionJournal).to receive(:record_new_signature_for).with(signature)
      run_the_job
    end

    it 'tells the relevant country petition journal to record a new signature' do
      expect(CountryPetitionJournal).to receive(:record_new_signature_for).with(signature)
      run_the_job
    end
  end

  context "when the petition is pending" do
    let(:petition) { FactoryGirl.create(:pending_petition, created_at: 2.days.ago, updated_at: 2.days.ago) }

    it "increments the petition count" do
      expect{ running_the_job }.to change{ petition.reload.signature_count }.by(1)
    end

    it "updates the petition to say it was updated just now" do
      expect{ running_the_job }.to change { petition.reload.updated_at }
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    it "updates the petition to say it was last signed at just now" do
      expect{ running_the_job }.to change { petition.reload.last_signed_at }
      expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
    end

    it 'tells the relevant constituency petition journal to record a new signature' do
      expect(ConstituencyPetitionJournal).to receive(:record_new_signature_for).with(signature)
      run_the_job
    end

    it 'tells the relevant country petition journal to record a new signature' do
      expect(CountryPetitionJournal).to receive(:record_new_signature_for).with(signature)
      run_the_job
    end

    context 'and the signature is a sponsor' do
      let(:petition) { FactoryGirl.create(:petition) }
      let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }
      let(:signature) { sponsor.create_signature(FactoryGirl.attributes_for(:pending_signature, petition: petition)) }

      it "sets petition state to validated" do
        expect {
          running_the_job
        }.to change { petition.reload.state }.from(Petition::PENDING_STATE).to(Petition::VALIDATED_STATE)
      end

      it 'sends email notification to the petition creator' do
        run_the_job
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq([petition.creator_signature.email])
      end

      context "and the petition is published" do
        before do
          petition.publish
          petition.reload
          ActionMailer::Base.deliveries.clear
        end

        it "does not send an email to the creator" do
          run_the_job
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end
    end
  end
end
