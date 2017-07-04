require 'rails_helper'

RSpec.describe MarkPetitionAsArchivedJob, type: :job do
  let(:petition) { FactoryGirl.create(:validated_petition, sponsors_signed: true) }
  let(:archived_petition) { FactoryGirl.create(:archived_petition, id: petition.id) }

  let :job do
    enqueued_jobs.first
  end

  context "when the petition has unarchived signatures" do
    it "doesn't mark the petition as archived" do
      expect {
        described_class.perform_now(petition, archived_petition)
      }.not_to change {
        petition.reload.archived_at
      }
    end

    it "enqueues another job to check in 5 minutes" do
      described_class.perform_now(petition, archived_petition)

      expect(job).to be_present
      expect(job[:job]).to eq(MarkPetitionAsArchivedJob)
      expect(job[:queue]).to eq("high_priority")
      expect(job[:at]).to be_within(1.second).of(5.minutes.from_now.to_f)
      expect(job[:args]).to eq([
        { "_aj_globalid" => "gid://epets/Petition/#{petition.id}" },
        { "_aj_globalid" => "gid://epets/Archived::Petition/#{archived_petition.id}" }
      ])
    end
  end

  context "when the petition has no unarchived signatures" do
    before do
      petition.signatures.each do |signature|
        archived_petition.signatures.create! do |s|
          s.uuid = signature.uuid
          s.state = signature.state
          s.number = signature.number
          s.name = signature.name
          s.email = signature.email
          s.postcode = signature.postcode
          s.location_code = signature.location_code
          s.constituency_id = signature.constituency_id
          s.ip_address = signature.ip_address
          s.perishable_token = signature.perishable_token
          s.unsubscribe_token = signature.unsubscribe_token
        end
      end
    end

    it "marks the petition as archived" do
      expect {
        described_class.perform_now(petition, archived_petition)
      }.to change {
        petition.reload.archived_at
      }.from(nil).to(be_within(1.second).of(Time.current))
    end

    it "doesn't enqueue another job to check in 5 minutes" do
      expect {
        described_class.perform_now(petition, archived_petition)
      }.not_to change {
        enqueued_jobs
      }
    end
  end
end
