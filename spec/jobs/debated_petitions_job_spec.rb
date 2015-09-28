require 'rails_helper'

RSpec.describe DebatedPetitionsJob, type: :job do
  context "when a petition is in the awaiting debate state and the debate date has not passed" do
    let(:petition) {
      FactoryGirl.build(:open_petition,
        debate_state: 'awaiting',
        scheduled_debate_date: Date.tomorrow
      )
    }

    before do
      petition.save
    end

    it "does not close the petition" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change{ petition.reload.debate_state }
    end
  end

  context "when a petition is in the awaiting debate state and the debate date has passed" do
    let(:petition) {
      FactoryGirl.build(:open_petition,
        debate_state: 'awaiting',
        scheduled_debate_date: Date.tomorrow
      )
    }

    before do
      travel_to(2.days.ago) do
        petition.save
      end
    end

    it "does close the petition" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.debate_state }.from("awaiting").to("debated")
    end
  end
end
