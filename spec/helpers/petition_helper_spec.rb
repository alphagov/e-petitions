require 'rails_helper'

RSpec.describe PetitionHelper, type: :helper do
  describe '#public_petition_facets_with_counts' do
    let(:public_petition_facets) { [:all, :open, :with_response] }
    before do
      def helper.public_petition_facets; end
      allow(helper).to receive(:public_petition_facets).and_return public_petition_facets
    end

    let(:facets) do
      {
        all: 100,
        open: 10,
        with_response: 20,
        hidden: 30
      }
    end
    let(:petition_search) { double(facets: facets) }

    subject { helper.public_petition_facets_with_counts(petition_search) }

    it 'returns each facet from the public facet list' do
      expect(subject.keys).to eq public_petition_facets
    end

    it 'returns each facet with its count from the search object' do
      public_petition_facets.each do |public_facet|
        expect(subject[public_facet]).to eq facets[public_facet.to_sym]
      end
    end

    it 'swallows the error and does not expose the facet if the search does not support it' do
      facets.default_proc = ->(_, failed_key) { raise ArgumentError, "Unsupported facet: #{failed_key.inspect}" }
      facets.delete(:with_response)
      expect {
        subject
      }.not_to raise_error
      expect(subject).not_to have_key('with_response')
    end
  end

  describe "#signatures_threshold_percentage" do

    context "when the signature count is less than the response threshold" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 239) }

      it "returns a percentage relative to the response threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("2.390%")
      end
    end

    context "when the signature count is greater than the response threshold and less than the debate threshold" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 76239) }

      it "returns a percentage relative to the debate threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("76.239%")
      end
    end

    context "when the signature count is greater than the debate threshold" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 127989) }

      it "returns 100 percent" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("100%")
      end
    end
  end
end
