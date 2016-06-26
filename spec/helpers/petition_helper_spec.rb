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
      let(:petition) { FactoryGirl.create(:petition) }

      it "returns the response threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_response)
      end
    end

    context "when the response threshold was reached recently" do
      let(:petition) { FactoryGirl.create(:petition, response_threshold_reached_at: 1.days.ago )}

      it "returns the debate threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_debate)
      end
    end

    context "when the debate threshold was reached recently" do
      let(:petition) { FactoryGirl.create(:petition, response_threshold_reached_at: 2.months.ago, debate_threshold_reached_at: 1.days.ago )}

      it "returns the debate threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_debate)
      end
    end

    context "when the response threshold was not reached but government has responded" do
      let(:petition) { FactoryGirl.create(:petition, government_response_at: 2.days.ago) }

      it "returns the debate threshold" do
        expect(helper.current_threshold(petition)).to eq(Site.threshold_for_debate)
      end
    end

  end

  describe "#signatures_threshold_percentage" do
    context "when the signature count is less than the response threshold" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 239) }

      it "returns a percentage relative to the response threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("2.39%")
      end
    end

    context "when the signature count is greater than the response threshold and less than the debate threshold" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 76239, response_threshold_reached_at: 1.day.ago) }

      it "returns a percentage relative to the debate threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("76.24%")
      end
    end

    context "when the signature count is greater than the debate threshold" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 127989, debate_threshold_reached_at: 1.day.ago) }

      it "returns 100 percent" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("100.00%")
      end
    end

    context "when the response threshold was not reached but government has responded" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 9878, government_response_at: 2.days.ago) }

      it "returns a percentage relative to the debate threshold" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("9.88%")
      end
    end

    context "when the actual percentage is less than 1" do
      let(:petition) { FactoryGirl.create(:petition, signature_count: 22 )}

      it "returns 1%" do
        expect(helper.signatures_threshold_percentage(petition)).to eq("1.00%")
      end
    end
  end

  describe '#api_signatures_by_country' do
    before do
      FactoryGirl.create(:location, :gb)
    end

    let(:petition) { FactoryGirl.create(:open_petition, signature_count: 22) }
    subject { helper.api_signatures_by_country(petition) }

    context 'when the petition has no country petition journals' do
      it 'returns a single "GB" entry claiming all the signatures' do
        expect(subject.size).to eq 1
        expect(subject.first.code).to eq 'GB'
        expect(subject.first.signature_count).to eq 22
      end
    end

    context 'when the petition has country petition journals created by validating signatures' do
      before do
        fr = FactoryGirl.create(:location, code: 'FR')
        de = FactoryGirl.create(:location, code: 'DE')
        es = FactoryGirl.create(:location, code: 'ES')
        FactoryGirl.create(:pending_signature, petition: petition, location_code: 'FR').validate!
        FactoryGirl.create(:pending_signature, petition: petition, location_code: 'DE').validate!
        # Note: these 2 GB sigs don't create a country petition journal as GB sigs are unrecorded (for now)
        FactoryGirl.create(:pending_signature, petition: petition, location_code: 'GB').validate!
        FactoryGirl.create(:pending_signature, petition: petition, location_code: 'GB').validate!
        FactoryGirl.create(:pending_signature, petition: petition, location_code: 'FR').validate!

        expect(CountryPetitionJournal.find_by(petition_id: petition.id, location_code: 'FR')).to be_present
        expect(CountryPetitionJournal.find_by(petition_id: petition.id, location_code: 'DE')).to be_present
        expect(CountryPetitionJournal.find_by(petition_id: petition.id, location_code: 'GB')).to be_nil

        expect(petition.cached_signature_count).to eq 27
      end

      it 'returns an entry for each country with signatures' do
        fr_data = subject.detect { |country| country.code == 'FR' }
        expect(fr_data).to be_present
        expect(fr_data.signature_count).to eq 2

        de_data = subject.detect { |country| country.code == 'DE' }
        expect(de_data).to be_present
        expect(de_data.signature_count).to eq 1
      end

      it 'does not include an entry for a country with no signatures' do
        es_data = subject.detect { |country| country.code == 'ES' }
        expect(es_data).to be_nil
      end

      it 'calculates a value for the "GB" entry by subtracting the counts from the other countries' do
        gb_data = subject.detect { |country| country.code == 'GB' }

        expect(gb_data.signature_count).to eq 24
      end

      context 'when there is a country petition journal recorded before we stopped doing so' do
        before do
          CountryPetitionJournal.for(petition, 'GB').update_column(:signature_count, 10)
        end

        it 'only includes 1 GB entry' do
          gb_data = subject.select { |country| country.code == 'GB' }
          expect(gb_data.count).to eq 1
        end

        it 'ignores the jounral in the db and exposes the calculated value' do
          gb_data = subject.detect { |country| country.code == 'GB' }
          expect(gb_data.signature_count).to eq 24
          expect(gb_data).not_to be_persisted
        end
      end
    end
  end
end
