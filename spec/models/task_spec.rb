require 'rails_helper'

RSpec.describe Task, type: :model do
  describe "indexes" do
    it { is_expected.to have_db_index(:name).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(60) }
  end

  describe ".run" do
    subject { described_class.find_by!(name: "task") }

    context "with the default period" do
      context "when the task has been newly created" do
        let(:now) { Time.current }

        before do
          described_class.create!(name: 'task', created_at: now, updated_at: now)
        end

        it "calls the block" do
          expect { |b| described_class.run("task", &b) }.to yield_control
        end

        it "updates the timestamp" do
          expect {
            described_class.run("task"){}
          }.to change {
            subject.reload.updated_at
          }.to(be_within(1.second).of(Time.current))
        end
      end

      context "when the period has not elapsed" do
        before do
          described_class.create!(name: 'task', created_at: 2.weeks.ago, updated_at: 6.hours.ago)
        end

        it "doesn't call the block" do
          expect { |b| described_class.run("task", &b) }.not_to yield_control
        end

        it "doesn't update the timestamp" do
          expect {
            described_class.run("task"){}
          }.not_to change {
            subject.reload.updated_at
          }
        end
      end

      context "when the period has elapsed" do
        before do
          described_class.create!(name: 'task', created_at: 2.weeks.ago, updated_at: 24.hours.ago)
        end

        it "calls the block" do
          expect { |b| described_class.run("task", &b) }.to yield_control
        end

        it "updates the timestamp" do
          expect {
            described_class.run("task"){}
          }.to change {
            subject.reload.updated_at
          }.to(be_within(1.second).of(Time.current))
        end
      end
    end

    context "with a custom period" do
      context "when the task has been newly created" do
        let(:now) { Time.current }

        before do
          described_class.create!(name: 'task', created_at: now, updated_at: now)
        end

        it "calls the block" do
          expect { |b| described_class.run("task", 30.minutes, &b) }.to yield_control
        end

        it "updates the timestamp" do
          expect {
            described_class.run("task", 30.minutes){}
          }.to change {
            subject.reload.updated_at
          }.to(be_within(1.second).of(Time.current))
        end
      end

      context "when the period has not elapsed" do
        before do
          described_class.create!(name: 'task', created_at: 2.weeks.ago, updated_at: 10.minutes.ago)
        end

        it "doesn't call the block" do
          expect { |b| described_class.run("task", 30.minutes, &b) }.not_to yield_control
        end

        it "doesn't update the timestamp" do
          expect {
            described_class.run("task", 30.minutes){}
          }.not_to change {
            subject.reload.updated_at
          }
        end
      end

      context "when the period has elapsed" do
        before do
          described_class.create!(name: 'task', created_at: 2.weeks.ago, updated_at: 1.hour.ago)
        end

        it "calls the block" do
          expect { |b| described_class.run("task", 30.minutes, &b) }.to yield_control
        end

        it "updates the timestamp" do
          expect {
            described_class.run("task", 30.minutes){}
          }.to change {
            subject.reload.updated_at
          }.to(be_within(1.second).of(Time.current))
        end
      end
    end
  end
end
