require 'rails_helper'

RSpec.describe CsvHelper, type: :helper do
  subject { helper.csv_escape(value) }

  context "when the value begins with '-'" do
    let(:value) { "-10 * 2" }

    it "escapes the value" do
      expect(subject).to eq("%2D10 * 2")
    end
  end

  context "when the value begins with '+'" do
    let(:value) { "+10 * 2" }

    it "escapes the value" do
      expect(subject).to eq("%2B10 * 2")
    end
  end

  context "when the value begins with '@'" do
    let(:value) { "@10 * 2" }

    it "escapes the value" do
      expect(subject).to eq("%4010 * 2")
    end
  end

  context "when the value begins with '='" do
    let(:value) { "=10 * 2" }

    it "escapes the value" do
      expect(subject).to eq("%3D10 * 2")
    end
  end

  context "when the value is a number" do
    let(:value) { 10 }

    it "converts it to a string" do
      expect(subject).to eq("10")
    end
  end

  context "when the value is a date" do
    let(:value) { Date.civil(2019, 7, 24) }

    it "converts it to a string" do
      expect(subject).to eq("2019-07-24")
    end
  end

  context "when the value is nil" do
    let(:value) { nil }

    it "returns nil" do
      expect(subject).to eq(nil)
    end
  end

  context "when the value is an empty string" do
    let(:value) { "" }

    it "returns nil" do
      expect(subject).to eq(nil)
    end
  end
end
