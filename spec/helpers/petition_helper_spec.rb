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

  describe "#current_threshold" do
    context "when the response threshold has never been reached" do
      let(:petition) { FactoryBot.create(:petition) }

      it "returns the response threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_response)
      end
    end

    context "when the response threshold was reached recently" do
      let(:petition) { FactoryBot.create(:petition, response_threshold_reached_at: 1.days.ago )}

      it "returns the debate threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_debate)
      end
    end

    context "when the debate threshold was reached recently" do
      let(:petition) { FactoryBot.create(:petition, response_threshold_reached_at: 2.months.ago, debate_threshold_reached_at: 1.days.ago )}

      it "returns the debate threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_debate)
      end
    end

    context "when the response threshold was not reached but government has responded" do
      let(:petition) { FactoryBot.create(:petition, government_response_at: 2.days.ago) }

      it "returns the debate threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_debate)
      end
    end
  end

  describe "#signatures_threshold_percentage" do
    context "when the signature count is less than the response threshold" do
      let(:petition) { FactoryBot.create(:petition, signature_count: 239) }

      it "returns a percentage relative to the response threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("2.39%")
      end
    end

    context "when the signature count is greater than the response threshold and less than the debate threshold" do
      let(:petition) { FactoryBot.create(:petition, signature_count: 76239, response_threshold_reached_at: 1.day.ago) }

      it "returns a percentage relative to the debate threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("76.24%")
      end
    end

    context "when the signature count is greater than the debate threshold" do
      let(:petition) { FactoryBot.create(:petition, signature_count: 127989, debate_threshold_reached_at: 1.day.ago) }

      it "returns 100 percent" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("100.00%")
      end
    end

    context "when the response threshold was not reached but government has responded" do
      let(:petition) { FactoryBot.create(:petition, signature_count: 9878, government_response_at: 2.days.ago) }

      it "returns a percentage relative to the debate threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("9.88%")
      end
    end

    context "when the actual percentage is less than 1" do
      let(:petition) { FactoryBot.create(:petition, signature_count: 22 )}

      it "returns 1%" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("1.00%")
      end
    end
  end

  describe "#reveal_government_response?" do
    context "when the param 'reveal_response' isn't set" do
      it "returns false" do
        expect(helper.reveal_government_response?).to eq(false)
      end
    end

    context "when the param 'reveal_response' is set to 'no'" do
      before do
        params[:reveal_response] = "no"
      end

      it "returns false" do
        expect(helper.reveal_government_response?).to eq(false)
      end
    end

    context "when the param 'reveal_response' is set to 'yes'" do
      before do
        params[:reveal_response] = "yes"
      end

      it "returns true" do
        expect(helper.reveal_government_response?).to eq(true)
      end
    end
  end
end
