require 'rails_helper'

RSpec.describe UpdatePetitionStatisticsJob, type: :job do
  let(:petition) { FactoryBot.create(:open_petition) }
  let(:statistics) { petition.statistics }

  it "updates the petition statistics" do
    expect {
      described_class.perform_now(petition)
    }.to change {
      statistics.reload.refreshed_at
    }.to(be_within(1.second).of(Time.current))
  end
end
