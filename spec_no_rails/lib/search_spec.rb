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
    sunspot.stub(:search).and_yield.and_return(results)
    subject.stub(:fulltext)
    subject.stub(:order_by)
    subject.stub(:adjust_solr_params).and_yield(params)
    subject.stub(:facet)
    subject.stub(:paginate)
    subject.stub(:with).and_return(criteria)
    SearchOrder.stub(:sort_order).and_return(sort_order)
  end

  context "counting states" do
    it "asks sunspot for the state facets" do
      subject.should_receive(:facet).with(:state)
      subject.state_counts_for("apples")
    end

    it "does not limit the query by state" do
      subject.should_receive(:fulltext).with("apples")
      subject.should_not_receive(:with).with(:state)
      subject.state_counts_for("apples")
    end

    it "returns nil if the state isn't found" do
      subject.state_counts_for("apples")['open'].should == 0
    end
  end

  context "searching" do
    it "performs a Sunspot search" do
      sunspot.should_receive(:search).with(petition).and_yield
      subject.execute("apples")
    end

    it "turns off the 'qf' and 'defType' parameters" do
      subject.execute("apples")
      params[:qf].should == ""
      params[:defType].should == ""
    end

    it "works with a single keyword" do
      subject.should_receive(:fulltext).with("apples")
      criteria.should_receive(:equal_to).with("rejected")
      subject.should_receive(:with).and_return(criteria)
      subject.execute("apples")
    end

    it "works with multiple keywords" do
      subject.should_receive(:fulltext).with("apples eggs")
      subject.execute("apples eggs")
    end

    it "only searches the first 10 words" do
      subject.should_receive(:fulltext).with("1 2 3 4 5 6 7 8 9 10")
      subject.execute("1 2 3 4 5 6 7 8 9 10 eleven")
    end

    context "a state of" do
      before do
        Time.stub_chain(:zone, :now, :utc => "now")
      end
      context "closed" do
        let(:state) { State::CLOSED_STATE }
        it "works" do
          criteria.should_receive(:equal_to).with("open")
          criteria.should_receive(:less_than).with("now")
          subject.should_receive(:with).with(:closed_at).and_return(criteria)
          subject.execute("apples")
        end
      end
      context "open" do
        let(:state) { State::OPEN_STATE }

        it "works" do
          criteria.should_receive(:equal_to).with("open")
          criteria.should_receive(:greater_than).with("now")
          subject.should_receive(:with).with(:closed_at).and_return(criteria)
          subject.execute("apples")
        end
      end

      context "hidden" do
        let(:state) { State::HIDDEN_STATE }

        it "shows no results" do
          subject.should_not_receive(:fulltext)
          subject.execute("apples")
        end
      end

      context "faked non-existent state" do
        let(:state) { "trying to hack <script>alert('hello')</script>" }
        it "shows no results" do
          subject.should_not_receive(:fulltext)
          subject.execute("apples")
        end
      end

      context "default state" do
        let(:state) { "" }
        it "shows no results" do
          subject.should_not_receive(:fulltext)
          subject.execute("apples")
        end
      end
    end

    it "translates '*' into spaces" do
      subject.should_receive(:fulltext).with("apples eggs")
      subject.execute("apples*eggs")
    end

    it "rejects a single '*'" do
      sunspot.should_not_receive(:search)
      subject.execute("*")
    end

    it "orders by the order param" do
      subject.should_receive(:order_by).with(sort_order)
      subject.execute("apples")
    end

    it "paginates by the page param" do
      subject.should_receive(:paginate).with(:page => page, :per_page => 20)
      subject.execute("apples")
    end

    context "configured to return less results" do
      subject { Search.new(options.merge(:per_page => 5)) }
      it "does indeed return less results" do
        subject.should_receive(:paginate).with(:page => page, :per_page => 5)
        subject.execute("apples")
      end
    end
  end
end
