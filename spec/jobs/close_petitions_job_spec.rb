require 'rails_helper'

RSpec.describe ClosePetitionsJob, type: :job do
  let!(:petition) { FactoryGirl.create(:open_petition, open_at: open_at) }

  context "when a petition is in the open state and closing date has not passed" do
    let(:open_at) { Site.opened_at_for_closing(1.day.from_now) }

    it "does not close the petition" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change{ petition.reload.state }
    end
  end

  context "when a petition is in the open state and closed_at has passed" do
    let(:open_at) { Site.opened_at_for_closing(1.day.ago) }

    it "does close the petition" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.state }.from('open').to('closed')
    end
  end
end
