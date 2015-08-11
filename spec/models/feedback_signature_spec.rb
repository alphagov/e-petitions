require 'rails_helper'

RSpec.describe FeedbackSignature, type: :model do
  let(:petition) { double(:petition) }
  let(:signature) { described_class.new(petition) }

  describe "#name" do
    it "returns 'Petitions team'" do
      expect(signature.name).to eq("Petitions team")
    end
  end

  describe "#email" do
    it "returns 'petitionscommittee@parliament.uk'" do
      expect(signature.email).to eq("petitionscommittee@parliament.uk")
    end
  end

  describe "#petition" do
    it "returns the petition passed to new" do
      expect(signature.petition).to eq(petition)
    end
  end

  describe "#unsubscribe_token" do
    it "returns a dummy token" do
      expect(signature.unsubscribe_token).to eq("ThisIsNotAToken")
    end
  end

  describe "#to_param" do
    it "returns a dummy id" do
      expect(signature.to_param).to eq("0")
    end
  end
end
