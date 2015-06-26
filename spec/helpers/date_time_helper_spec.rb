require 'rails_helper'

RSpec.describe DateTimeHelper, type: :helper do
  describe "#local_date_time" do
    it "displays nothing if the date is nil" do
      expect(helper.local_date_time_format(nil)).to be_nil
    end

    it "displays a GMT time in winter" do
      date_time = DateTime.parse("17:45 25th December 2012")
      expect(helper.local_date_time_format(date_time)).to eq("25/12/2012 17:45")
    end

    it "displays the BST time in summer" do
      date_time = DateTime.parse("17:45 15th June 2012")
      expect(helper.local_date_time_format(date_time)).to eq("15/06/2012 18:45")
    end
  end

  describe "#last_updated_at_time" do
    it "returns nil when no date" do
      expect(helper.last_updated_at_time(nil)).to eq(nil)
    end

    it "returns just the time" do
      date_time = DateTime.parse("17:45 25th December 2012")
      expect(helper.last_updated_at_time(date_time)).to eq("17:45 GMT")
    end

    it "returns just the time" do
      date_time = DateTime.parse("17:45 25th July 2012 GMT")
      expect(helper.last_updated_at_time(date_time)).to eq("18:45 BST")
    end
  end

  describe "#waiting_for_in_words" do
    let(:now) { Time.current.noon }

    context "when the date is nil" do
      it "returns nil" do
        expect(helper.waiting_for_in_words(nil)).to be_nil
      end
    end

    context "when the date is today" do
      let(:date) { 2.hours.ago(now) }

      it "returns 'Waiting for less than a day'" do
        expect(helper.waiting_for_in_words(date)).to eq("Waiting for less than a day")
      end
    end

    context "when the date is yesterday" do
      let(:date) { 1.day.ago(now) }

      it "returns 'Waiting for 1 day'" do
        expect(helper.waiting_for_in_words(date)).to eq("Waiting for 1 day")
      end
    end

    context "when the date is last week" do
      let(:date) { 7.days.ago(now) }

      it "returns 'Waiting for 7 days'" do
        expect(helper.waiting_for_in_words(date)).to eq("Waiting for 7 days")
      end
    end

    context "when the response threshold was reached last month" do
      let(:date) { 30.days.ago(now) }

      it "returns 'Waiting for 30 days'" do
        expect(helper.waiting_for_in_words(date)).to eq("Waiting for 30 days")
      end
    end

    context "when the response threshold was reached 3 years ago" do
      let(:date) { 1095.days.ago(now) }

      it "returns 'Waiting for 1,095 days'" do
        expect(helper.waiting_for_in_words(date)).to eq("Waiting for 1,095 days")
      end
    end
  end
end
