require 'rails_helper'

RSpec.describe EmailThresholdReminderJob, type: :job do
  let!(:moderator_1) { FactoryGirl.create(:moderator_user, email: "alice@parliament.uk") }
  let!(:moderator_2) { FactoryGirl.create(:moderator_user, email: "bob@parliament.uk") }

  let!(:petition_1) { FactoryGirl.create(:open_petition, signature_count: 11) }
  let!(:petition_2) { FactoryGirl.create(:open_petition, signature_count: 10) }
  let!(:petition_3) { FactoryGirl.create(:open_petition, signature_count: 9) }
  let!(:petition_4) { FactoryGirl.create(:open_petition, notified_by_email: true) }

  let(:deliveries) { ActionMailer::Base.deliveries }
  let(:email) { deliveries.last }

  before do
    allow(Site).to receive(:threshold_for_debate).and_return(10)
  end

  it "send out an email alert" do
    expect {
      described_class.perform_now
    }.to change {
      deliveries.size
    }.by(1)
  end

  it "delivers it to all the moderators" do
    described_class.perform_now

    expect(email).to deliver_to("alice@parliament.uk", "bob@parliament.uk")
    expect(email).to have_subject("Petitions alert")
    expect(email).to have_body_text("2 petitions require action")
  end

  it "updates notified by email on petition 1" do
    expect {
      described_class.perform_now
    }.to change {
      petition_1.reload.notified_by_email
    }.from(false).to(true)
  end

  it "updates notified by email on petition 2" do
    expect {
      described_class.perform_now
    }.to change {
      petition_2.reload.notified_by_email
    }.from(false).to(true)
  end
end
