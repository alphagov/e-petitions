require 'rails_helper'

RSpec.describe ClosePetitionsJob, type: :job do
  context "when a petition is in the open state and closed_at has not passed" do
    let!(:petition) { FactoryGirl.create(:open_petition, closed_at: 3.days.from_now) }

    it "does not close the petition" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.not_to change{ petition.reload.state }
    end
  end

  context "when a petition is in the open state and closed_at has passed" do
    let!(:petition) { FactoryGirl.create(:open_petition, closed_at: 3.days.ago) }

    it "does close the petition" do
      expect{
        perform_enqueued_jobs {
          described_class.perform_later
        }
      }.to change{ petition.reload.state }.from('open').to('closed')
    end
  end
end
