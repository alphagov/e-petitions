require "rails_helper"

RSpec.describe TrendingSignatureCollection do
  let(:subject) { described_class.new(petition) }
  let(:petition) { FactoryGirl.build(:open_petition) }
  let(:time) { Time.parse("1 Jan 2017 05:30:00 GMT") }
  let(:today) { Date.current }
  let(:two_days_ago) { today - 2.days }

  around do |example|
    travel_to(time) { example.run }
  end

  describe "#hourly_intervals" do
    it "returns an enumerator" do
      expect(subject.hourly_intervals).to be_instance_of(Enumerator)
    end

    context "with a trending petition journal" do
      before do
        FactoryGirl.create(
          :trending_petition_journal, petition: petition, date: time.to_date
        )
      end

      it "returns a collection of hourly intervals" do
        subject.hourly_intervals.each do |interval|
          expect(interval).to be_instance_of(SignatureInterval)
        end
      end

      it "returns an interval for each hour in the past" do
        expect(subject.hourly_intervals.count).to eq 6
      end
    end

    context "with sporadic trending petition journals" do
      before do
        FactoryGirl.create(
          :trending_petition_journal, petition: petition, date: today
        )
        FactoryGirl.create(
          :trending_petition_journal, petition: petition, date: two_days_ago
        )
      end

      it "returns a collection of hourly intervals" do
        subject.hourly_intervals.each do |interval|
          expect(interval).to be_instance_of(SignatureInterval)
        end
      end

      it "returns an interval for each hour in the past" do
        expect(subject.hourly_intervals.count).to eq 54
      end

      it "starts on the date of the first journal" do
        expect(subject.hourly_intervals.first.starts_at.to_date)
          .to eq two_days_ago
      end
    end
  end
end
