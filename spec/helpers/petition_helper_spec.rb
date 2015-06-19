require 'rails_helper'

RSpec.describe PetitionHelper, type: :helper do
  describe "#waiting_for_response_in_words" do
    let(:now) { Time.current.noon }

    context "when the response threshold has not been reached" do
      let(:petition) { double(:petition, response_threshold_reached_at: nil) }

      it "returns nil" do
        expect(helper.waiting_for_response_in_words(petition)).to be_nil
      end
    end

    context "when the response threshold was reached today" do
      let(:petition) { double(:petition, response_threshold_reached_at: 2.hours.ago(now)) }

      it "returns 'Waiting for less than a day'" do
        expect(helper.waiting_for_response_in_words(petition)).to eq("Waiting for less than a day")
      end
    end

    context "when the response threshold was reached yesterday" do
      let(:petition) { double(:petition, response_threshold_reached_at: 1.day.ago(now)) }

      it "returns 'Waiting for 1 day'" do
        expect(helper.waiting_for_response_in_words(petition)).to eq("Waiting for 1 day")
      end
    end

    context "when the response threshold was reached last week" do
      let(:petition) { double(:petition, response_threshold_reached_at: 7.days.ago(now)) }

      it "returns 'Waiting for 7 days'" do
        expect(helper.waiting_for_response_in_words(petition)).to eq("Waiting for 7 days")
      end
    end

    context "when the response threshold was reached last month" do
      let(:petition) { double(:petition, response_threshold_reached_at: 30.days.ago(now)) }

      it "returns 'Waiting for 30 days'" do
        expect(helper.waiting_for_response_in_words(petition)).to eq("Waiting for 30 days")
      end
    end

    context "when the response threshold was reached 3 years ago" do
      let(:petition) { double(:petition, response_threshold_reached_at: 1095.days.ago(now)) }

      it "returns 'Waiting for 1,095 days'" do
        expect(helper.waiting_for_response_in_words(petition)).to eq("Waiting for 1,095 days")
      end
    end
  end
end
