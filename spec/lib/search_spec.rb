require 'search'
require 'state'
require 'search_order'

describe Search do
  let(:params) { {} }
  let(:sort_order) { double }
  let(:page) { double }
  let(:state) { State::REJECTED_STATE }
  let(:sunspot) { double }
  let(:petition) { double }
  let(:results) { double.as_null_object }
  let(:criteria) { double.as_null_object }
  let(:options) {{ :state => state, :page => page, :sunspot_interface => sunspot, :target => petition }}
  subject { Search.new(options) }

  before do
    allow(sunspot).to receive(:search).and_yield.and_return(results)
    allow(subject).to receive(:fulltext)
    allow(subject).to receive(:order_by)
    allow(subject).to receive(:adjust_solr_params).and_yield(params)
    allow(subject).to receive(:facet)
    allow(subject).to receive(:paginate)
    allow(subject).to receive(:with).and_return(criteria)
    allow(SearchOrder).to receive(:sort_order).and_return(sort_order)
  end

  context "counting states" do
    it "asks sunspot for the state facets" do
      expect(subject).to receive(:facet).with(:state)
      subject.state_counts_for("apples")
    end

    it "does not limit the query by state" do
      expect(subject).to receive(:fulltext).with("apples")
      expect(subject).not_to receive(:with).with(:state)
      subject.state_counts_for("apples")
    end

    it "returns nil if the state isn't found" do
      expect(subject.state_counts_for("apples")['open']).to eq(0)
    end
  end

  context "searching" do
    it "performs a Sunspot search" do
      expect(sunspot).to receive(:search).with(petition).and_yield
      subject.execute("apples")
    end

    it "turns off the 'qf' and 'defType' parameters" do
      subject.execute("apples")
      expect(params[:qf]).to eq("")
      expect(params[:defType]).to eq("")
    end

    it "works with a single keyword" do
      expect(subject).to receive(:fulltext).with("apples")
      expect(criteria).to receive(:equal_to).with("rejected")
      expect(subject).to receive(:with).and_return(criteria)
      subject.execute("apples")
    end

    it "works with multiple keywords" do
      expect(subject).to receive(:fulltext).with("apples eggs")
      subject.execute("apples eggs")
    end

    it "only searches the first 10 words" do
      expect(subject).to receive(:fulltext).with("1 2 3 4 5 6 7 8 9 10")
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
          expect(subject).to receive(:with).with(:closed_at).and_return(criteria)
          subject.execute("apples")
        end
      end
      context "open" do
        let(:state) { State::OPEN_STATE }

        it "works" do
          expect(criteria).to receive(:equal_to).with("open")
          expect(criteria).to receive(:greater_than).with("now")
          expect(subject).to receive(:with).with(:closed_at).and_return(criteria)
          subject.execute("apples")
        end
      end

      context "hidden" do
        let(:state) { State::HIDDEN_STATE }

        it "shows no results" do
          expect(subject).not_to receive(:fulltext)
          subject.execute("apples")
        end
      end

      context "faked non-existent state" do
        let(:state) { "trying to hack <script>alert('hello')</script>" }
        it "shows no results" do
          expect(subject).not_to receive(:fulltext)
          subject.execute("apples")
        end
      end

      context "default state" do
        let(:state) { "" }
        it "shows no results" do
          expect(subject).not_to receive(:fulltext)
          subject.execute("apples")
        end
      end
    end

    it "translates '*' into spaces" do
      expect(subject).to receive(:fulltext).with("apples eggs")
      subject.execute("apples*eggs")
    end

    it "rejects a single '*'" do
      expect(sunspot).not_to receive(:search)
      subject.execute("*")
    end

    it "orders by the order param" do
      expect(subject).to receive(:order_by).with(sort_order)
      subject.execute("apples")
    end

    it "paginates by the page param" do
      expect(subject).to receive(:paginate).with(:page => page, :per_page => 20)
      subject.execute("apples")
    end

    context "configured to return less results" do
      subject { Search.new(options.merge(:per_page => 5)) }
      it "does indeed return less results" do
        expect(subject).to receive(:paginate).with(:page => page, :per_page => 5)
        subject.execute("apples")
      end
    end
  end
end
