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

    it "adds a facet scope to the facet_definitions class attribute" do
      browseable.facet(:open, scope)
      expect(browseable.facet_definitions).to eq({ open: scope })
    end
  end

  describe ".filter" do
    let(:scope) { ->(param){ double(:scope) } }

    it "adds a filter scope to the filter_definitions class attribute" do
      browseable.filter(:topics, scope)
      expect(browseable.filter_definitions).to eq({ topics: scope })
    end
  end

  describe ".search" do
    let(:params) { {} }
    let(:search) { browseable.search(params) }

    it "returns an instance of Browseable::Search" do
      expect(search).to be_an_instance_of(Browseable::Search)
    end
  end

  describe Browseable::Search do
    let(:scopes)  { { all: -> { self }, open: -> { self } } }
    let(:filters) { {} }
    let(:klass)   { double(:klass, facet_definitions: scopes, filter_definitions: filters) }
    let(:params)  { { q: 'search', page: '3'} }
    let(:search)  { described_class.new(klass, params) }

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

    describe "#previous_params" do
      let(:arel_table) { double(:arel_table) }
      let(:petition)   { double(:petition) }
      let(:petitions)  { [petition] }
      let(:results)    { double(:results, to_a: petitions) }

      before do
        allow(klass).to receive(:basic_search).with('search').and_return(klass)
        allow(arel_table).to receive(:[]).with("*").and_return("*")
        allow(klass).to receive(:basic_search).with('search').and_return(klass)
        allow(klass).to receive(:except).with(:select).and_return(klass)
        allow(klass).to receive(:arel_table).and_return(arel_table)
        allow(klass).to receive(:select).with("*").and_return(klass)
        allow(klass).to receive(:except).with(:order).and_return(klass)
        allow(klass).to receive(:paginate).with(page: 3, per_page: 50).and_return(results)
        allow(results).to receive(:to_a).and_return(petitions)
        allow(results).to receive(:previous_page).and_return(2)
      end

      context "with default params" do
        it "returns a hash of params for building the previous page link" do
          expect(search.previous_params).to eq({ q: 'search', state: :all, page: 2 })
        end
      end

      context "with a custom state param" do
        let(:params) { { q: 'search', page: '3', state: 'open' } }

        it "returns a hash of params for building the previous page link" do
          expect(search.previous_params).to eq({ q: 'search', state: :open, page: 2 })
        end
      end

      context "with a filter param" do
        let(:params) { { q: 'search', page: '3', topics: 'covid-19' } }
        let(:scope) { ->(param){ topics(param) } }
        let(:filters) { { topics: scope } }

        before do
          expect(klass).to receive(:topics).with('covid-19').and_return(klass)
        end

        it "returns a hash of params for building the previous page link" do
          expect(search.previous_params).to eq({ q: 'search', state: :all, page: 2, topics: 'covid-19' })
        end
      end
    end

    describe "#next_params" do
      let(:arel_table) { double(:arel_table) }
      let(:petition)   { double(:petition) }
      let(:petitions)  { [petition] }
      let(:results)    { double(:results, to_a: petitions) }

      before do
        allow(klass).to receive(:basic_search).with('search').and_return(klass)
        allow(arel_table).to receive(:[]).with("*").and_return("*")
        allow(klass).to receive(:basic_search).with('search').and_return(klass)
        allow(klass).to receive(:except).with(:select).and_return(klass)
        allow(klass).to receive(:arel_table).and_return(arel_table)
        allow(klass).to receive(:select).with("*").and_return(klass)
        allow(klass).to receive(:except).with(:order).and_return(klass)
        allow(klass).to receive(:paginate).with(page: 3, per_page: 50).and_return(results)
        allow(results).to receive(:to_a).and_return(petitions)
        allow(results).to receive(:next_page).and_return(4)
      end

      context "with default params" do
        it "returns a hash of params for building the previous page link" do
          expect(search.next_params).to eq({ q: 'search', state: :all, page: 4 })
        end
      end

      context "with a custom state param" do
        let(:params) { { q: 'search', page: '3', state: 'open' } }

        it "returns a hash of params for building the previous page link" do
          expect(search.next_params).to eq({ q: 'search', state: :open, page: 4 })
        end
      end

      context "with a filter param" do
        let(:params) { { q: 'search', page: '3', topics: 'covid-19' } }
        let(:scope) { ->(param){ topics(param) } }
        let(:filters) { { topics: scope } }

        before do
          expect(klass).to receive(:topics).with('covid-19').and_return(klass)
        end

        it "returns a hash of params for building the previous page link" do
          expect(search.next_params).to eq({ q: 'search', state: :all, page: 4, topics: 'covid-19' })
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

    describe "#in_batches" do
      # Use an array that quacks like the expected ActiveRecord::Relation instance
      class BatchifiedArray < Array
        alias :find_each :each
      end

      let(:search_results) { BatchifiedArray.new([1,2,3]) }

      before do
        allow(search).to receive(:execute_search).and_return search_results
      end

      it "uses ActiveRecord::Batches#find_each to load the results in batches" do
        expect(search_results).to receive(:find_each).and_call_original
        search.in_batches {|a| }
      end

      it "calls the block with each result" do
        block = ->(a) { }
        expect(block).to receive(:call).with(1).once
        expect(block).to receive(:call).with(2).once
        expect(block).to receive(:call).with(3).once
        search.in_batches(&block)
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

  describe Browseable::Filters do
    let(:klass) { double(:klass, filter_definitions: filter_definitions) }
    let(:filters) { described_class.new(klass, params) }

    describe "implicit conversion" do
      let(:filter_definitions) { {} }
      let(:params) { {} }

      it "can be merged with another hash" do
        expect{ {}.merge(filters) }.not_to raise_error
      end
    end

    describe "#to_hash" do
      let(:scope) { ->{ double(:scope) } }
      let(:filter_definitions) { { topics: scope } }

      context "when the key is not present in the params hash" do
        let(:params) { {} }

        it "returns a hash without the filter key" do
          expect(filters.to_hash).to eq({})
        end
      end

      context "when the key is present in the params hash" do
        let(:params) { { topics: "covid-19" } }

        it "returns a hash with the filter key" do
          expect(filters.to_hash).to eq({ topics: "covid-19" })
        end
      end
    end
  end
end
