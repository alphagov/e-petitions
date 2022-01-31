require 'rails_helper'

RSpec.describe EmailConstituenciesJob, type: :job do
  let!(:petition) { FactoryBot.create(:closed_petition) }
  let!(:mailshot) { FactoryBot.create(:petition_mailshot, petition: petition) }
  let!(:constituency_ids) { %w[3427 3320 3703] }
  let!(:requested_at) { Time.now }
  let!(:requested_at_iso8601) { requested_at.getutc.iso8601(6) }

  it "enqueues an EmailConstituencyJob job for every constituency" do
    described_class.perform_now(mailshot, constituency_ids, requested_at: requested_at)

    expect(EmailConstituencyJob).to have_been_enqueued
      .on_queue(:high_priority).with(
        petition: petition,
        mailshot: mailshot,
        scope: { constituency_id: "3427" },
        requested_at: requested_at_iso8601
      )

    expect(EmailConstituencyJob).to have_been_enqueued
      .on_queue(:high_priority).with(
        petition: petition,
        mailshot: mailshot,
        scope: { constituency_id: "3320" },
        requested_at: requested_at_iso8601
      )

    expect(EmailConstituencyJob).to have_been_enqueued
      .on_queue(:high_priority).with(
        petition: petition,
        mailshot: mailshot,
        scope: { constituency_id: "3703" },
        requested_at: requested_at_iso8601
      )
  end
end
