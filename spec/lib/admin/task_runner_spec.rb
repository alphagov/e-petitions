require 'rails_helper'

RSpec.describe Admin::TaskRunner do
  describe ".run" do
    let(:params) { double(:params) }
    let(:instance) { double(:instance) }

    it "instantiates an instance and calls run" do
      expect(described_class).to receive(:new).with(params).and_return(instance)
      expect(instance).to receive(:run).and_return(%w[task_1])

      expect(described_class.run(params)).to eq(true)
    end

    it "returns false if no tasks are run" do
      expect(described_class).to receive(:new).with(params).and_return(instance)
      expect(instance).to receive(:run).and_return([])

      expect(described_class.run(params)).to eq(false)
    end

    describe "when calling #run raises an error" do
      let(:exception) { StandardError.new("Something bad happened") }

      it "returns false" do
        expect(described_class).to receive(:new).with(params).and_return(instance)
        expect(instance).to receive(:run).and_raise(exception)
        expect(Appsignal).to receive(:send_exception).with(exception)

        expect(described_class.run(params)).to eq(false)
      end
    end
  end

  describe "tasks" do
    describe "backfill_constituencies" do
      let(:now) { Time.utc(2017, 9, 18, 8, 0, 0) }

      around do |example|
        travel_to(now) { example.run }
      end

      context "since 1 week ago" do
        let(:params) do
          {
            tasks: %w[backfill_constituencies],
            backfill_constituencies: {
              since: "week"
            }
          }.with_indifferent_access
        end

        let(:job) do
          {
            job: BackfillConstituenciesJob,
            args: [
              { "since" => "2017-09-11T09:00:00+01:00", "_aj_symbol_keys" => ["since"] }
            ],
            queue: "low_priority"
          }
        end

        it "enqueues a BackfillConstituenciesJob job" do
          expect {
            described_class.run(params)
          }.to change {
            enqueued_jobs
          }.from([]).to([job])
        end
      end

      context "since 1 month ago" do
        let(:params) do
          {
            tasks: %w[backfill_constituencies],
            backfill_constituencies: {
              since: "month"
            }
          }.with_indifferent_access
        end

        let(:job) do
          {
            job: BackfillConstituenciesJob,
            args: [
              { "since" => "2017-08-18T09:00:00+01:00", "_aj_symbol_keys" => ["since"] }
            ],
            queue: "low_priority"
          }
        end

        it "enqueues a BackfillConstituenciesJob job" do
          expect {
            described_class.run(params)
          }.to change {
            enqueued_jobs
          }.from([]).to([job])
        end
      end

      context "since 3 months ago" do
        let(:params) do
          {
            tasks: %w[backfill_constituencies],
            backfill_constituencies: {
              since: "three_months"
            }
          }.with_indifferent_access
        end

        let(:job) do
          {
            job: BackfillConstituenciesJob,
            args: [
              { "since" => "2017-06-18T09:00:00+01:00", "_aj_symbol_keys" => ["since"] }
            ],
            queue: "low_priority"
          }
        end

        it "enqueues a BackfillConstituenciesJob job" do
          expect {
            described_class.run(params)
          }.to change {
            enqueued_jobs
          }.from([]).to([job])
        end
      end
    end
  end
end
