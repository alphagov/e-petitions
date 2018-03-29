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

    context "when the time span crosses the spring DST boundary" do
      let(:now) { Time.utc(2016, 4, 11, 11, 0, 0).in_time_zone }
      let(:date) { 30.days.ago(now) }

      around do |example|
        travel_to(now) { example.run }
      end

      it "returns 'Waiting for 30 days'" do
        expect(helper.waiting_for_in_words(date)).to eq("Waiting for 30 days")
      end
    end

    context "when the time span crosses the autumn DST boundary" do
      let(:now) { Time.utc(2016, 11, 11, 12, 0, 0).in_time_zone }
      let(:date) { 30.days.ago(now) }

      around do |example|
        travel_to(now) { example.run }
      end

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

  describe "#scheduled_for_debate_in_words" do
    context "when the date is today" do
      let(:date) { Date.parse("11/11/2016") }

      it "returns 'Scheduled for debate on 11 November 2016'" do
        expect(helper.scheduled_for_debate_in_words(date)).to eq("Scheduled for debate on 11 November 2016")
      end
    end

    context "when the date is today" do
      let(:date) { Date.current }

      it "returns 'Scheduled for debate today'" do
        expect(helper.scheduled_for_debate_in_words(date)).to eq("Scheduled for debate today")
      end
    end

    context "when the date is tomorrow" do
      let(:date) { Date.tomorrow }

      it "returns 'Scheduled for debate tomorrow'" do
        expect(helper.scheduled_for_debate_in_words(date)).to eq("Scheduled for debate tomorrow")
      end
    end
  end

  describe "#christmas_period?" do
    context "when the date is before the 22nd Dec" do
      around do |example|
        travel_to("2017-12-21") { example.run }
      end

      it "returns false" do
        expect(helper.christmas_period?).to eq(false)
      end
    end

    context "when the date is the 22nd Dec" do
      around do |example|
        travel_to("2017-12-22") { example.run }
      end

      it "returns true" do
        expect(helper.christmas_period?).to eq(true)
      end
    end

    context "when the date is between 22nd Dec and 4th Jan" do
      around do |example|
        travel_to("2017-12-26") { example.run }
      end

      it "returns true" do
        expect(helper.christmas_period?).to eq(true)
      end
    end

    context "when the date is the 4th Jan" do
      around do |example|
        travel_to("2018-01-04") { example.run }
      end

      it "returns true" do
        expect(helper.christmas_period?).to eq(true)
      end
    end

    context "when the date is after the 4th Jan" do
      around do |example|
        travel_to("2018-01-05") { example.run }
      end

      it "returns false" do
        expect(helper.christmas_period?).to eq(false)
      end
    end
  end

  describe "#easter_period?" do
    context "when the date is before the 30th Mar" do
      around do |example|
        travel_to("2018-03-29") { example.run }
      end

      it "returns false" do
        expect(helper.easter_period?).to eq(false)
      end
    end

    context "when the date is the 30th Mar" do
      around do |example|
        travel_to("2018-03-30") { example.run }
      end

      it "returns true" do
        expect(helper.easter_period?).to eq(true)
      end
    end

    context "when the date is between 30th Mar and 9th Apr" do
      around do |example|
        travel_to("2018-04-01") { example.run }
      end

      it "returns true" do
        expect(helper.easter_period?).to eq(true)
      end
    end

    context "when the date is the 9th Apr" do
      around do |example|
        travel_to("2018-04-09") { example.run }
      end

      it "returns true" do
        expect(helper.easter_period?).to eq(true)
      end
    end

    context "when the date is after the 9th Apr" do
      around do |example|
        travel_to("2018-04-10") { example.run }
      end

      it "returns false" do
        expect(helper.easter_period?).to eq(false)
      end
    end
  end
end
