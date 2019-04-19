require 'rails_helper'

RSpec.describe ResetPetitionSignatureCountJob, type: :job do
  let(:current_time) { "2019-04-19T12:57:00Z" }
  let(:exception_class) { ResetPetitionSignatureCountJob::InvalidSignatureCount }

  let!(:petition) do
    FactoryBot.create(:open_petition,
      created_at: "2019-04-17T12:57:00Z",
      last_signed_at: "2019-04-19T12:56:00Z",
      signature_count: 100,
      creator_attributes: { validated_at: "2019-04-18T12:57:00Z" }
    )
  end

  before do
    allow(Appsignal).to receive(:send_exception)
  end

  it "updates the signature count" do
    expect {
      described_class.perform_now(petition, current_time)
    }.to change { petition.reload.signature_count }.from(100).to(1)
  end

  it "updates the last_signed_at timestamp" do
    expect {
      described_class.perform_now(petition, current_time)
    }.to change { petition.reload.last_signed_at }.to(current_time.in_time_zone)
  end

  it "updates the updated_at timestamp" do
    expect {
      described_class.perform_now(petition, current_time)
    }.to change { petition.reload.updated_at }.to(current_time.in_time_zone)
  end

  it "notifies AppSignal" do
    described_class.perform_now(petition, current_time)
    expect(Appsignal).to have_received(:send_exception).with(an_instance_of(exception_class))
  end
end
