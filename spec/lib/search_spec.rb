require 'search'
require 'state'
require 'search_order'
require 'rails_helper'

describe Search do
  class FakeSunspot
    def initialize(results)
      @results = results
    end

    def search(*args, &block)
      @context = eval('self', block.binding)
      instance_eval &block
      @context = nil
      @results
    end

    def fulltext(*args);end
    def order_by(*args);end
    def adjust_solr_params(*args);end
    def facet(*args);end
    def paginate(*args);end
    def with(*args);end
    def method_missing(method, *args, &block)
      return super if @context.nil?
      @context.send(method, *args, &block)
    end
  end

  let(:params) { {} }
  let(:sort_order) { double }
  let(:page) { double }
  let(:state) { State::REJECTED_STATE }
  let(:sunspot) { FakeSunspot.new(results) }
  let(:petition) { double }
  let(:results) { double.as_null_object }
  let(:criteria) { double.as_null_object }
  let(:options) {{ :state => state, :page => page, :sunspot_interface => sunspot, :target => petition }}
  subject { Search.new(options) }

  before do
    allow(sunspot).to receive(:fulltext)
    allow(sunspot).to receive(:order_by)
    allow(sunspot).to receive(:adjust_solr_params).and_yield(params)
    allow(sunspot).to receive(:facet)
    allow(sunspot).to receive(:paginate)
    allow(sunspot).to receive(:with).and_return(criteria)
    allow(SearchOrder).to receive(:sort_order).and_return(sort_order)
  end

  context "counting states" do
    it "asks sunspot for the state facets" do
      expect(sunspot).to receive(:facet).with(:state)
      subject.state_counts_for("apples")
    end

    it "does not limit the query by state" do
      expect(sunspot).to receive(:fulltext).with("apples")
      expect(sunspot).not_to receive(:with).with(:state)
      subject.state_counts_for("apples")
    end

    it "returns nil if the state isn't found" do
      expect(subject.state_counts_for("apples")['open']).to eq(0)
    end
  end

  context "searching" do
    it "performs a Sunspot search" do
      expect(sunspot).to receive(:search).with(petition)
      subject.execute("apples")
    end

    it "turns off the 'qf' and 'defType' parameters" do
      subject.execute("apples")
      expect(params[:qf]).to eq("")
      expect(params[:defType]).to eq("")
    end

    it "works with a single keyword" do
      expect(sunspot).to receive(:fulltext).with("apples")
      expect(criteria).to receive(:equal_to).with("rejected")
      expect(sunspot).to receive(:with).and_return(criteria)
      subject.execute("apples")
    end

    it "works with multiple keywords" do
      expect(sunspot).to receive(:fulltext).with("apples eggs")
      subject.execute("apples eggs")
    end

    it "only searches the first 10 words" do
      expect(sunspot).to receive(:fulltext).with("1 2 3 4 5 6 7 8 9 10")
      subject.execute("1 2 3 4 5 6 7 8 9 10 eleven")
    end

    context "a state of" do
      before do
        allow(Time).to receive_message_chain(:zone, :now, :utc => "now")
      end
      context "closed" do
        let(:state) { State::CLOSED_STATE }
        it "works" do
          expect(criteria).to receive(:equal_to).with("open")
          expect(criteria).to receive(:less_than).with("now")
          expect(sunspot).to receive(:with).with(:closed_at).and_return(criteria)
          subject.execute("apples")
        end
      end
      context "open" do
        let(:state) { State::OPEN_STATE }

        it "works" do
          expect(criteria).to receive(:equal_to).with("open")
          expect(criteria).to receive(:greater_than).with("now")
          expect(sunspot).to receive(:with).with(:closed_at).and_return(criteria)
          subject.execute("apples")
        end
      end

      context "hidden" do
        let(:state) { State::HIDDEN_STATE }

        it "shows no results" do
          expect(sunspot).not_to receive(:fulltext)
          subject.execute("apples")
        end
      end

      context "faked non-existent state" do
        let(:state) { "trying to hack <script>alert('hello')</script>" }
        it "shows no results" do
          expect(sunspot).not_to receive(:fulltext)
          subject.execute("apples")
        end
      end

      context "default state" do
        let(:state) { "" }
        it "shows no results" do
          expect(sunspot).not_to receive(:fulltext)
          subject.execute("apples")
        end
      end
    end

    it "translates '*' into spaces" do
      expect(sunspot).to receive(:fulltext).with("apples eggs")
      subject.execute("apples*eggs")
    end

    it "rejects a single '*'" do
      expect(sunspot).not_to receive(:search)
      subject.execute("*")
    end

    it "orders by the order param" do
      expect(sunspot).to receive(:order_by).with(sort_order)
      subject.execute("apples")
    end

    it "paginates by the page param" do
      expect(sunspot).to receive(:paginate).with(:page => page, :per_page => 20)
      subject.execute("apples")
    end

    context "configured to return less results" do
      subject { Search.new(options.merge(:per_page => 5)) }
      it "does indeed return less results" do
        expect(sunspot).to receive(:paginate).with(:page => page, :per_page => 5)
        subject.execute("apples")
      end
    end
  end
end
