require 'rails_helper'

RSpec.describe ClosePetitionsJob, type: :job do
  context "for a petition opened in the winter" do
    let!(:petition) {
      FactoryBot.create(:open_petition, referred: true, open_at: "2015-12-29T10:00:00Z")
    }

    around do |example|
      travel_to(now)
      example.run
      travel_back
    end

    context "and the closing date has not passed" do
      let(:now) { "2016-06-28T07:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
          }
        }.not_to change{ petition.reload.state }
      end
    end

    context "and the closing date has passed" do
      let(:now) { "2016-06-29T07:00:00Z".in_time_zone }

      it "does change the petition debate state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
          }
        }.to change{ petition.reload.state }.from("open").to("closed")
      end
    end
  end

  context "for a petition opened in the summer" do
    let!(:petition) {
      FactoryBot.create(:open_petition, referred: true, open_at: "2016-06-29T10:00:00Z")
    }

    around do |example|
      travel_to(now)
      example.run
      travel_back
    end

    context "and the closing date has not passed" do
      let(:now) { "2016-12-28T07:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
          }
        }.not_to change{ petition.reload.state }
      end
    end

    context "and the closing date has passed" do
      let(:now) { "2016-12-29T07:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(Date.tomorrow.beginning_of_day.iso8601)
          }
        }.to change{ petition.reload.state }.from("open").to("closed")
      end
    end
  end
end
