require 'rails_helper'

RSpec.describe StopPetitionsEarlyJob, type: :job do
  let(:state) { Petition::PENDING_STATE }
  let(:special_consideration) { false }
  let(:created_at) { dissolution_at - 1.month }
  let(:dissolution_at) { "2017-05-02T23:00:01Z".in_time_zone }
  let(:scheduled_at) { dissolution_at - 2.weeks }
  let(:before_dissolution) { dissolution_at - 1.week }
  let(:notification_cutoff_at) { "2017-03-31T23:00:00Z".in_time_zone }
  let(:job) { Delayed::Job.last }
  let(:jobs) { Delayed::Job.all.to_a }
  let(:creator) { petition.creator }

  let!(:petition) do
    FactoryBot.create(
      :"#{state}_petition", created_at: created_at,
      special_consideration: special_consideration
    )
  end

  around do |example|
    without_test_adapter { example.run }
  end

  before do
    allow(Parliament).to receive(:notification_cutoff_at).and_return(notification_cutoff_at)
    allow(Parliament).to receive(:dissolved?).and_return(true)

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
    it "stops the petition" do
      expect {
        travel_to(dissolution_at) {
          Delayed::Worker.new.work_off
        }
      }.to change {
        petition.reload.state
      }.from("pending").to("stopped")
    end

    it "sets the stopped_at to the correct timestamp" do
      expect {
        travel_to(dissolution_at) {
          Delayed::Worker.new.work_off
        }
      }.to change {
        petition.reload.stopped_at
      }.from(nil).to(dissolution_at)
    end
  end

  context "when the petition is pending" do
    let(:state) { Petition::PENDING_STATE }

    context "and was created before the cutoff date" do
      let(:created_at) { notification_cutoff_at - 1.week }

      it "doesn't send a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.not_to change {
          deliveries.size
        }
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("pending").to("stopped")
      end
    end

    context "and was created after the cutoff date" do
      let(:created_at) { notification_cutoff_at + 1.week }

      it "doesn't send a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.not_to change {
          deliveries.size
        }
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("pending").to("stopped")
      end
    end
  end

  context "when the petition is validated" do
    let(:state) { Petition::VALIDATED_STATE }
    let(:email) { :notify_creator_of_validated_petition_being_stopped }

    context "and was created before the cutoff date" do
      let(:created_at) { notification_cutoff_at - 1.week }

      it "doesn't send a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.not_to change {
          deliveries.size
        }
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("validated").to("stopped")
      end
    end

    context "and was created after the cutoff date" do
      let(:created_at) { notification_cutoff_at + 1.week }

      before do
        expect(PetitionMailer).to receive(email).with(creator).and_call_original
      end

      it "sends a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          deliveries.size
        }.by(1)
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("validated").to("stopped")
      end
    end

    context "but is flagged for special consideration" do
      let(:created_at) { notification_cutoff_at + 1.week }
      let(:special_consideration) { true }

      before do
        expect(PetitionMailer).not_to receive(email)
      end

      it "doesn't send a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.not_to change {
          deliveries.size
        }
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("validated").to("stopped")
      end
    end
  end

  context "when the petition is sponsored" do
    let(:state) { Petition::SPONSORED_STATE }
    let(:email) { :notify_creator_of_sponsored_petition_being_stopped }

    context "and was created before the cutoff date" do
      let(:created_at) { notification_cutoff_at - 1.week }

      it "doesn't send a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.not_to change {
          deliveries.size
        }
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("sponsored").to("stopped")
      end
    end

    context "and was created after the cutoff date" do
      let(:created_at) { notification_cutoff_at + 1.week }

      before do
        expect(PetitionMailer).to receive(email).with(creator).and_call_original
      end

      it "sends a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          deliveries.size
        }.by(1)
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("sponsored").to("stopped")
      end
    end

    context "but is flagged for special consideration" do
      let(:created_at) { notification_cutoff_at + 1.week }
      let(:special_consideration) { true }

      before do
        expect(PetitionMailer).not_to receive(email)
      end

      it "doesn't send a notification email" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.not_to change {
          deliveries.size
        }
      end

      it "stops the petition" do
        expect {
          travel_to(dissolution_at) {
            Delayed::Worker.new.work_off
          }
        }.to change {
          petition.reload.state
        }.from("sponsored").to("stopped")
      end
    end
  end
end
