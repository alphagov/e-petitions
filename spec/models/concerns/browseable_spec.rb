require 'rails_helper'

RSpec.describe Browseable, type: :model do
  let(:browseable) do
    Class.new do
      include Browseable

      def self.all
        self
      end
    end
  end

  describe "including the module" do
    it "adds a facet_definitions class attribute" do
      expect(browseable).to respond_to(:facet_definitions)
      expect(browseable.facet_definitions).to eq({})
    end
  end

  describe ".facet" do
    let(:scope) { ->{ double(:scope) } }

    it "adds a facet scope to the facets class attribute" do
      browseable.facet(:open, scope)
      expect(browseable.facet_definitions).to eq({ open: scope })
    end
  end

  describe ".search" do
    let(:params) { Hash.new }
    let(:search) { browseable.search(params) }

    it "returns an instance of Browseable::Search" do
      expect(search).to be_an_instance_of(Browseable::Search)
    end
  end

  describe Browseable::Search do
    let(:scopes) { { all: -> { self }, open: -> { self } } }
    let(:klass)  { double(:klass, facet_definitions: scopes) }
    let(:params) { { q: 'search', page: '3'} }
    let(:search) { described_class.new(klass, params) }

    it "is enumerable" do
      expect(search).to respond_to(:each)
    end

    describe "delegated methods" do
      subject{ search }

      it { is_expected.to delegate_method(:offset).to(:results) }
      it { is_expected.to delegate_method(:out_of_bounds?).to(:results) }
      it { is_expected.to delegate_method(:next_page).to(:results) }
      it { is_expected.to delegate_method(:previous_page).to(:results) }
      it { is_expected.to delegate_method(:total_entries).to(:results) }
      it { is_expected.to delegate_method(:total_pages).to(:results) }
      it { is_expected.to delegate_method(:each).to(:results) }
      it { is_expected.to delegate_method(:empty?).to(:results) }
      it { is_expected.to delegate_method(:map).to(:results) }
      it { is_expected.to delegate_method(:to_a).to(:results) }
    end

    describe "#current_page" do
      it "returns the page number from the params" do
        expect(search.current_page).to eq(3)
      end

      context "when the page parameter is invalid" do
        let(:params) { { q: 'search', page: 'invalid' } }

        it "defaults to 1" do
          expect(search.current_page).to eq(1)
        end
      end

      context "when the page parameter is missing" do
        let(:params) { { q: 'search' } }

        it "defaults to 1" do
          expect(search.current_page).to eq(1)
        end
      end
    end

    describe "#facets" do
      it "returns an instance of Browseable::Facets" do
        expect(search.facets).to be_an_instance_of(Browseable::Facets)
      end
    end

    describe "#first_page?" do
      context "when the current page is 1" do
        let(:params) { { q: 'search', page: '1' } }

        it "returns true" do
          expect(search.first_page?).to be true
        end
      end

      context "when the current page is not 1" do
        let(:params) { { q: 'search', page: '2' } }

        it "returns false" do
          expect(search.first_page?).to be false
        end
      end
    end

    describe "#last_page?" do
      context "when the current page is the same as the total pages" do
        let(:params) { { q: 'search', page: '10' } }

        it "returns true" do
          expect(search).to receive(:total_pages).and_return(10)
          expect(search.last_page?).to be true
        end
      end

      context "when the current page is not the same as the total pages" do
        let(:params) { { q: 'search', page: '10' } }

        it "returns true" do
          expect(search).to receive(:total_pages).and_return(20)
          expect(search.last_page?).to be false
        end
      end
    end

    describe "#query" do
      it "returns the query string" do
        expect(search.query).to eq("search")
      end
    end

    describe "#page_size" do
      context "when the count param is not set" do
        it "returns 50" do
          expect(search.page_size).to eq(50)
        end
      end

      context "when the count param is set to less than 50" do
        let(:params) { { q: 'search', page: '1', count: '3' } }

        it "returns 3" do
          expect(search.page_size).to eq(3)
        end
      end

      context "when the count param is set to more than 50" do
        let(:params) { { q: 'search', page: '1', count: '500' } }

        it "returns 50" do
          expect(search.page_size).to eq(50)
        end
      end

      context "when the count param is set to zero" do
        let(:params) { { q: 'search', page: '1', count: '0' } }

        it "returns 1" do
          expect(search.page_size).to eq(1)
        end
      end

      context "when the count param is set to less than 0" do
        let(:params) { { q: 'search', page: '1', count: '-10' } }

        it "returns 1" do
          expect(search.page_size).to eq(1)
        end
      end
    end

    describe "#scope" do
      context "when the search scope is valid" do
        let(:params) { { q: 'search', page: '3', state: 'open'} }

        it "returns the current scope as a symbol" do
          expect(search.scope).to eq(:open)
        end
      end

      context "when the search scope is invalid" do
        let(:params) { { q: 'search', page: '3', state: 'unknown'} }

        it "returns :all" do
          expect(search.scope).to eq(:all)
        end
      end

      context "when the search scope is not present" do
        let(:params) { { q: 'search', page: '3' } }

        it "returns all" do
          expect(search.scope).to eq(:all)
        end
      end
    end

    describe "#scoped?" do
      context "when the search scope is valid" do
        let(:params) { { q: 'search', page: '3', state: 'open'} }

        it "returns true" do
          expect(search.scoped?).to eq(true)
        end
      end

      context "when the search scope is invalid" do
        let(:params) { { q: 'search', page: '3', state: 'unknown'} }

        it "returns false" do
          expect(search.scoped?).to eq(false)
        end
      end

      context "when the search scope is not present" do
        let(:params) { { q: 'search', page: '3' } }

        it "returns false" do
          expect(search.scoped?).to eq(false)
        end
      end
    end

    describe "#search?" do
      context "when there is a query param" do
        it "returns true" do
          expect(search.search?).to be true
        end
      end

      context "when there is no query param" do
        let(:params) { { page: '1' } }

        it "returns false" do
          expect(search.search?).to be false
        end
      end
    end

    describe "#to_a" do
      let(:arel_table) { double(:arel_table) }
      let(:petition)   { double(:petition) }
      let(:petitions)  { [petition] }
      let(:results)    { double(:results, to_a: petitions) }

      context "when there is a search term" do
        before do
          # This list of stubs is effectively testing the implementation of the
          # execute_search private method, however this is important because of
          # the need to exclude the ranking column added by the textacular gem
          # which can add a significant performance penalty.

          expect(arel_table).to receive(:[]).with("*").and_return("*")
          expect(klass).to receive(:basic_search).with('search').and_return(klass)
          expect(klass).to receive(:except).with(:select).and_return(klass)
          expect(klass).to receive(:arel_table).and_return(arel_table)
          expect(klass).to receive(:select).with("*").and_return(klass)
          expect(klass).to receive(:except).with(:order).and_return(klass)
          expect(klass).to receive(:paginate).with(page: 3, per_page: 50).and_return(results)
          expect(results).to receive(:to_a).and_return(petitions)
        end

        context "and the search is not scoped" do
          let(:params) { { q: 'search', page: '3'} }

          it "returns the list of petitions" do
            expect(search.to_a).to eq(petitions)
          end
        end

        context "and the search is scoped" do
          let(:params) { { q: 'search', page: '3', state: 'all'} }

          it "merges in the facet scope" do
            expect(klass).to receive(:instance_exec).and_return(klass)
            expect(search.to_a).to eq(petitions)
          end
        end
      end

      context "when there is not a search term" do
        before do
          expect(klass).to receive(:paginate).with(page: 3, per_page: 50).and_return(results)
        end

        context "and the search is not scoped" do
          let(:params) { { page: '3'} }

          it "returns the list of petitions" do
            expect(search.to_a).to eq(petitions)
          end
        end

        context "and the search is scoped" do
          let(:params) { { page: '3', state: 'all'} }

          it "merges in the facet scope" do
            expect(klass).to receive(:instance_exec).and_return(klass)
            expect(search.to_a).to eq(petitions)
          end
        end
      end
    end
  end

  describe Browseable::Facets do
    let(:scope)  { ->{ where(state: 'open') } }
    let(:query)  { double(:query) }
    let(:scopes) { { open: scope } }
    let(:klass)  { double(:klass, facet_definitions: scopes) }
    let(:facets) { described_class.new(klass) }

    describe "delegated methods" do
      subject{ facets }

      it { is_expected.to delegate_method(:facet_definitions).to(:klass) }
      it { is_expected.to delegate_method(:key?).to(:facet_definitions) }
      it { is_expected.to delegate_method(:has_key?).to(:facet_definitions) }
      it { is_expected.to delegate_method(:keys).to(:facet_definitions) }
    end

    describe "#[]" do
      it "raises ArgumentError for unknown facets" do
        expect{ facets[:unknown] }.to raise_error(ArgumentError)
      end

      it "returns the count for known facets" do
        expect(klass).to receive(:where).with(state: 'open').and_return(query)
        expect(query).to receive(:count).and_return(999)
        expect(facets[:open]).to eq(999)
      end
    end

    describe "#key?" do
      it "returns false when a key doesn't exist" do
        expect(facets.key?(:unknown)).to eq(false)
      end

      it "returns true when a key exists" do
        expect(facets.key?(:open)).to eq(true)
      end

      it "doesn't execute the facet query" do
        expect(klass).not_to receive(:where)
        expect(facets.key?(:open)).to eq(true)
      end
    end

    describe "#keys" do
      it "returns the list of facet keys" do
        expect(facets.keys).to eq([:open])
      end
    end

    describe "#slice" do
      before do
        scopes[:pending] = -> { where(state: 'pending') }

        open_query = double(:query)
        allow(klass).to receive(:where).with(state: 'open').and_return(open_query)
        allow(open_query).to receive(:count).and_return(999)

        pending_query = double(:query)
        allow(klass).to receive(:where).with(state: 'pending').and_return(pending_query)
        allow(pending_query).to receive(:count).and_return(20)
      end

      it 'returns a hash with only the specified keys and their counts' do
        expect(facets.slice(:open)).to eq({open: 999})
      end

      it 'accepts keys as strings' do
        expect(facets.slice('pending')).to eq({pending: 20})
      end

      it 'returns a hash with keys ordered by the supplied keys' do
        expect(facets.slice(:pending, :open).keys).to eq([:pending, :open])
      end

      it 'does not raise if asked for unknown keys' do
        expect {
          facets.slice(:unknown)
        }.not_to raise_error
      end

      it 'does not include unknown keys in the returned hash' do
        expect(facets.slice(:unknown)).to eq({})
      end
    end
  end
end
