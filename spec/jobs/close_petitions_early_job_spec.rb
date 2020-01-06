require 'rails_helper'

RSpec.describe ClosePetitionsEarlyJob, type: :job do
  let(:dissolution_at) { "2017-05-02T23:00:01Z".in_time_zone }
  let(:open_at) { dissolution_at - 4.weeks }
  let(:scheduled_at) { dissolution_at - 2.weeks }
  let(:before_dissolution) { dissolution_at - 1.week }
  let(:job) { Delayed::Job.last }
  let(:jobs) { Delayed::Job.all.to_a }

  let!(:petition) { FactoryBot.create(:open_petition, open_at: open_at) }

  around do |example|
    without_test_adapter { example.run }
  end

  before do
    travel_to(scheduled_at) {
      described_class.schedule_for(dissolution_at)
    }
  end

  it "enqueues the job" do
    expect(jobs).to eq([job])
  end

  context "before the scheduled date" do
    it "doesn't perform the enqueued job" do
      expect {
        travel_to(before_dissolution) {
          Delayed::Worker.new.work_off
        }
      }.not_to change {
        petition.reload.state
      }
    end
  end

  context "after the scheduled date" do
    it "closes the petition" do
      expect {
        travel_to(dissolution_at) {
          Delayed::Worker.new.work_off
        }
      }.to change {
        petition.reload.state
      }.from("open").to("closed")
    end

    it "sets the closed_at to the correct timestamp" do
      expect {
        travel_to(dissolution_at) {
          Delayed::Worker.new.work_off
        }
      }.to change {
        petition.reload.closed_at
      }.from(nil).to(dissolution_at)
    end
  end
end
