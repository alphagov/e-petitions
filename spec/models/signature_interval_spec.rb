require "rails_helper"

RSpec.describe SignatureInterval do
  let(:starts_at) { Time.now }
  let(:ends_at) { Time.now + 1.hour }
  let(:count) { 10 }
  let(:subject) { described_class.new(starts_at: starts_at, ends_at: ends_at, count: count) }

  describe "#starts_at" do
    it "returns the starts_at passed in" do
      expect(subject.starts_at).to eq starts_at
    end
  end

  describe "#ends_at" do
    it "returns the ends_at passed in" do
      expect(subject.ends_at).to eq ends_at
    end
  end

  describe "#count" do
    it "returns the count passed in" do
      expect(subject.count).to eq count
    end
  end
end
