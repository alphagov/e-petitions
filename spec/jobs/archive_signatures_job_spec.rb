require 'rails_helper'

RSpec.describe ArchiveSignaturesJob, type: :job do
  let(:petition) { FactoryGirl.create(:validated_petition, sponsors_signed: true) }
  let(:archived_petition) { FactoryGirl.create(:archived_petition, id: petition.id) }
  let(:signature_ids) { petition.signatures.order(:id).pluck(:id).in_groups_of(2) }

  let :args do
    [
      { "_aj_globalid" => "gid://epets/Petition/#{petition.id}" },
      { "_aj_globalid" => "gid://epets/Archived::Petition/#{archived_petition.id}" }
    ]
  end

  let :job_1 do
    { job: ArchiveSignatureJob, args: args + [signature_ids[0]], queue: "high_priority" }
  end

  let :job_2 do
    { job: ArchiveSignatureJob, args: args + [signature_ids[1]], queue: "high_priority" }
  end

  let :job_3 do
    { job: ArchiveSignatureJob, args: args + [signature_ids[2]], queue: "high_priority" }
  end

  it "creates an ArchiveSignatureJob for each batch of signatures" do
    expect {
      described_class.perform_now(petition, archived_petition, limit: 2)
    }.to change {
      enqueued_jobs
    }.from([]).to([job_1, job_2, job_3])
  end
end
