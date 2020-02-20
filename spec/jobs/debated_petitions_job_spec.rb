require 'rails_helper'

RSpec.describe DebatedPetitionsJob, type: :job do
  context "for a petition with a scheduled debate date in the winter" do
    let(:petition) {
      FactoryBot.build(:open_petition,
        debate_state: "scheduled",
        scheduled_debate_date: "2015-12-29"
      )
    }

    let(:open_at) { "2015-12-01T10:00:00Z".in_time_zone }

    before do
      travel_to(open_at) { petition.save }
      travel_to(now)
    end

    after do
      travel_back
    end

    context "and the debate date has not passed" do
      let(:now) { "2015-12-28T07:15:00Z".in_time_zone }

      it "does not change the petition debate state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.iso8601)
          }
        }.not_to change{ petition.reload.debate_state }
      end
    end

    context "and the debate date has passed" do
      let(:now) { "2015-12-29T07:15:00Z".in_time_zone }

      it "does change the petition debate state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.iso8601)
          }
        }.to change{ petition.reload.debate_state }.from("scheduled").to("debated")
      end
    end
  end

  context "for a petition with a scheduled debate date in the summer" do
    let(:petition) {
      FactoryBot.build(:open_petition,
        debate_state: "scheduled",
        scheduled_debate_date: "2016-06-29"
      )
    }

    let(:open_at) { "2016-06-01T10:00:00Z".in_time_zone }

    before do
      travel_to(open_at) { petition.save }
      travel_to(now)
    end

    after do
      travel_back
    end

    context "and the debate date has not passed" do
      let(:now) { "2016-06-28T07:15:00Z".in_time_zone }

      it "does not change the petition debate state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.iso8601)
          }
        }.not_to change{ petition.reload.debate_state }
      end
    end

    context "and the debate date has passed" do
      let(:now) { "2016-06-29T07:15:00Z".in_time_zone }

      it "does change the petition debate state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.iso8601)
          }
        }.to change{ petition.reload.debate_state }.from("scheduled").to("debated")
      end
    end
  end
end
