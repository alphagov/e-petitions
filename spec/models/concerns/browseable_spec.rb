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
      browseable.filter(:topic, scope)
      expect(browseable.filter_definitions).to eq({ topic: scope })
    end
  end

  describe ".query" do
    it "adds column to search on" do
      browseable.query(:name)
      expect(browseable.query_columns).to eq([Browseable::Query::Column.new("name", "english", false)])
    end

    it "allows overriding the search configuration" do
      browseable.query(:name, config: "simple")
      expect(browseable.query_columns).to eq([Browseable::Query::Column.new("name", "simple", false)])
    end

    it "allows overriding whether the column accepts nulls" do
      browseable.query(:name, null: true)
      expect(browseable.query_columns).to eq([Browseable::Query::Column.new("name", "english", true)])
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
    let(:columns) { [Browseable::Query::Column.new('action', 'english', false)] }
    let(:klass)   { double(:klass, facet_definitions: scopes, filter_definitions: filters, query_columns: columns, default_page_size: 50, max_page_size: 50) }
    let(:params)  { { q: 'search', page: '3'} }
    let(:search)  { described_class.new(klass, params) }

    let(:connection) { double(:connection) }

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
      it { is_expected.to delegate_method(:to_a).to(:results) }
      it { is_expected.to delegate_method(:to_ary).to(:results) }
      it { is_expected.to delegate_method(:each).to(:to_a) }
      it { is_expected.to delegate_method(:map).to(:to_a) }
      it { is_expected.to delegate_method(:size).to(:to_a) }
    end

    describe "#empty?" do
      context "when total_entries is zero" do
        before do
          expect(search).to receive(:total_entries).and_return(0)
        end

        it "returns true" do
          expect(search.empty?).to eq(true)
        end
      end

      context "when total_entries is not zero" do
        before do
          expect(search).to receive(:total_entries).and_return(1)
        end

        it "returns false" do
          expect(search.empty?).to eq(false)
        end
      end
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

      let(:sql) { %[((to_tsvector('english', "petitions"."action"::text)) @@ plainto_tsquery('english', :query))] }

      before do
        allow(klass).to receive(:quoted_table_name).and_return('"petitions"')
        allow(klass).to receive(:connection).and_return(connection)
        allow(connection).to receive(:quote_column_name).with('action').and_return('"action"')
        allow(klass).to receive(:where).with([sql, query: "search"]).and_return(klass)
        allow(klass).to receive(:paginate).with(page: 3, per_page: 50).and_return(results)
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
        let(:params) { { q: 'search', page: '3', topic: 'covid-19' } }
        let(:scope) { ->(param){ topic(param) } }
        let(:filters) { { topic: scope } }

        before do
          expect(klass).to receive(:topic).with('covid-19').and_return(klass)
        end

        it "returns a hash of params for building the previous page link" do
          expect(search.previous_params).to eq({ q: 'search', state: :all, page: 2, topic: 'covid-19' })
        end
      end
    end

    describe "#next_params" do
      let(:arel_table) { double(:arel_table) }
      let(:petition)   { double(:petition) }
      let(:petitions)  { [petition] }
      let(:results)    { double(:results, to_a: petitions) }

      let(:sql) { %[((to_tsvector('english', "petitions"."action"::text)) @@ plainto_tsquery('english', :query))] }

      before do
        allow(klass).to receive(:quoted_table_name).and_return('"petitions"')
        allow(klass).to receive(:connection).and_return(connection)
        allow(connection).to receive(:quote_column_name).with('action').and_return('"action"')
        allow(klass).to receive(:where).with([sql, query: "search"]).and_return(klass)
        allow(klass).to receive(:paginate).with(page: 3, per_page: 50).and_return(results)
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
        let(:params) { { q: 'search', page: '3', topic: 'covid-19' } }
        let(:scope) { ->(param){ topic(param) } }
        let(:filters) { { topic: scope } }

        before do
          expect(klass).to receive(:topic).with('covid-19').and_return(klass)
        end

        it "returns a hash of params for building the previous page link" do
          expect(search.next_params).to eq({ q: 'search', state: :all, page: 4, topic: 'covid-19' })
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

        it "returns the default page size" do
          expect(search.page_size).to eq(50)
        end
      end

      context "when the count param is set to less than 0" do
        let(:params) { { q: 'search', page: '1', count: '-10' } }

        it "returns the default page size" do
          expect(search.page_size).to eq(50)
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

      let(:sql) { %[((to_tsvector('english', "petitions"."action"::text)) @@ plainto_tsquery('english', :query))] }

      context "when there is a search term" do
        before do
          allow(klass).to receive(:quoted_table_name).and_return('"petitions"')
          allow(klass).to receive(:connection).and_return(connection)
          allow(connection).to receive(:quote_column_name).with('action').and_return('"action"')
          allow(klass).to receive(:where).with([sql, query: "search"]).and_return(klass)
          allow(klass).to receive(:paginate).with(page: 3, per_page: 50).and_return(results)
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
    let(:scope)   { ->{ where(state: 'open') } }
    let(:query)   { double(:query) }
    let(:scopes)  { { open: scope } }
    let(:klass)   { double(:klass, facet_definitions: scopes, filter_definitions: {}) }
    let(:facets)  { described_class.new(klass, filters) }
    let(:filters) { Browseable::Filters.new(klass, {}) }

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
      let(:filter_definitions) { { topic: scope } }

      context "when the key is not present in the params hash" do
        let(:params) { {} }

        it "returns a hash without the filter key" do
          expect(filters.to_hash).to eq({})
        end
      end

      context "when the key is present in the params hash" do
        let(:params) { { topic: "covid-19" } }

        it "returns a hash with the filter key" do
          expect(filters.to_hash).to eq({ topic: "covid-19" })
        end
      end
    end
  end

  describe Browseable::Query do
    let(:klass) { double(:klass, query_columns: query_columns) }
    let(:query_columns) { [] }

    subject { described_class.new(klass, "search") }

    it { is_expected.to delegate_method(:query_columns).to(:klass) }
    it { is_expected.to delegate_method(:connection).to(:klass) }
    it { is_expected.to delegate_method(:quoted_table_name).to(:klass) }
    it { is_expected.to delegate_method(:quote_column_name).to(:connection) }
    it { is_expected.to delegate_method(:inspect).to(:to_s) }
    it { is_expected.to delegate_method(:present?).to(:to_s) }

    describe "#build" do
      let(:connection) { double(:connection) }

      before do
        allow(klass).to receive(:quoted_table_name).and_return('"petitions"')
        allow(klass).to receive(:connection).and_return(connection)
        allow(connection).to receive(:quote_column_name).with('id').and_return('"id"')
        allow(connection).to receive(:quote_column_name).with('action').and_return('"action"')
        allow(connection).to receive(:quote_column_name).with('background').and_return('"background"')
        allow(connection).to receive(:quote_column_name).with('additional_details').and_return('"additional_details"')
      end

      context "when there are no columns" do
        it "returns nil" do
          expect(subject.build).to be_nil
        end
      end

      context "when there is one column" do
        let(:query_columns) do
          [ Browseable::Query::Column.new("action", "english", false) ]
        end

        it "returns a where condition" do
          expect(subject.build).to eq [
            %[((to_tsvector('english', "petitions"."action"::text)) @@ plainto_tsquery('english', :query))], { query: "search" }
          ]
        end

        context "and the column has a custom search configuration" do
          let(:query_columns) do
            [ Browseable::Query::Column.new("action", "simple", false) ]
          end

          it "returns a where condition" do
            expect(subject.build).to eq [
              %[((to_tsvector('simple', "petitions"."action"::text)) @@ plainto_tsquery('english', :query))], { query: "search" }
            ]
          end
        end

        context "and the column allows nulls" do
          let(:query_columns) do
            [ Browseable::Query::Column.new("action", "english", true) ]
          end

          it "returns a where condition" do
            expect(subject.build).to eq [
              %[((to_tsvector('english', COALESCE("petitions"."action", '')::text)) @@ plainto_tsquery('english', :query))], { query: "search" }
            ]
          end
        end
      end

      context "when there is more than one column" do
        let(:query_columns) do
          [
            Browseable::Query::Column.new("id", "simple", false),
            Browseable::Query::Column.new("action", "english", false),
            Browseable::Query::Column.new("background", "english", false),
            Browseable::Query::Column.new("additional_details", "english", true)
          ]
        end

        it "returns a where condition" do
          expect(subject.build).to eq [
            %Q[((#{[
              %[to_tsvector('simple', "petitions"."id"::text)],
              %[to_tsvector('english', "petitions"."action"::text)],
              %[to_tsvector('english', "petitions"."background"::text)],
              %[to_tsvector('english', COALESCE("petitions"."additional_details", '')::text)]
            ].join(' || ')}) @@ plainto_tsquery('english', :query))], { query: "search" }
          ]
        end
      end
    end

    describe "#to_s" do
      it "returns the query param" do
        expect(subject.to_s).to eq("search")
      end
    end
  end
end
