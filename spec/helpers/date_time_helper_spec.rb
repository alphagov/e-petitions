require 'rails_helper'

RSpec.describe DateTimeHelper, type: :helper do
  describe "#short_date_format" do
    let(:date) { Date.civil(2020, 10, 31) }

    context "in English" do
      around do |example|
        I18n.with_locale(:"en-GB") { example.run }
      end

      it "returns the correct date format" do
        expect(helper.short_date_format(date)).to eq("31 October 2020")
      end
    end

    context "in Welsh" do
      around do |example|
        I18n.with_locale(:"cy-GB") { example.run }
      end

      it "returns the correct date format" do
        expect(helper.short_date_format(date)).to eq("31 Hydref 2020")
      end
    end
  end

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

  describe "#scheduled_for_debate_in_words" do
    context "in English" do
      around do |example|
        I18n.with_locale(:"en-GB") { example.run }
      end

      context "when the date is in the future" do
        let(:date) { Date.parse("11/11/2016") }

        it "returns 'Scheduled for debate on 11 November 2016'" do
          expect(helper.scheduled_for_debate_in_words(date)).to eq("Scheduled for debate on 11 November 2016")
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

    context "in Welsh" do
      around do |example|
        I18n.with_locale(:"cy-GB") { example.run }
      end

      context "when the date is in the future" do
        let(:date) { Date.parse("11/11/2016") }

        it "returns 'Trefnwyd dadl ar gyfer 11 Tachwedd 2016'" do
          expect(helper.scheduled_for_debate_in_words(date)).to eq("Trefnwyd dadl ar gyfer 11 Tachwedd 2016")
        end
      end

      context "when the date is today" do
        let(:date) { Date.current }

        it "returns 'Trefnwyd cynnal dadl heddiw'" do
          expect(helper.scheduled_for_debate_in_words(date)).to eq("Trefnwyd cynnal dadl heddiw")
        end
      end

      context "when the date is tomorrow" do
        let(:date) { Date.tomorrow }

        it "returns 'Trefnwyd cynnal dadl yfory'" do
          expect(helper.scheduled_for_debate_in_words(date)).to eq("Trefnwyd cynnal dadl yfory")
        end
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
