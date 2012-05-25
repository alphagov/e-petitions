require 'spec_helper'

describe PetitionResults do

  describe "new petition search" do
    let(:petitions){ double }
    let(:searcher){ double }
    let(:search){ double }
    let(:counts){ double }
    let(:options) do
      {
        :search_term    => "quick brown fox",
        :state => Petition::OPEN_STATE,
        :per_page       => 5,
        :page_number    => '3',
        :order          => 'asc',
        :sort           => 'title'
      }
    end

    before(:each) do
      Search.stub(:new => searcher)
      searcher.stub(:execute => search, :state_counts_for => counts)
      search.stub(:results => petitions)
    end

    describe "searching" do
      it "creates the search object with the correct configuration" do
        Search.should_receive(:new).with(hash_including(
          :state    => Petition::OPEN_STATE,
          :per_page => 5,
          :page     => 3,
          :order    => 'asc',
          :sort     => 'title'
        ))
        PetitionResults.new(options)
      end

      it "creates a different search object if specified" do
        alternative_strategy = double
        alternative_strategy.should_receive(:new).and_return(searcher)
        PetitionResults.new(options.merge(:search_strategy => alternative_strategy))
      end

      it "queries the search subsystem" do
        searcher.should_receive(:execute).with(options[:search_term]).and_return(search)
        PetitionResults.new(options)
      end

      it "asks the search server for petitions" do
        petition_search = PetitionResults.new(options)
        petition_search.petitions.should == petitions
      end

      it "sets the state counts" do
        petition_search = PetitionResults.new(options)
        petition_search.state_counts.should == counts
      end
    end

    it "defaults the state to open" do
      options.delete(:state)
      petition_search = PetitionResults.new(options)
      petition_search.state.should == Petition::OPEN_STATE
    end

    it "converts the page number to an integer" do
      petition_search = PetitionResults.new(options)
      petition_search.page_number.should == 3
    end

    it "always returns at least a page number of 1" do
      options.delete(:page_number)
      petition_search = PetitionResults.new(options)
      petition_search.page_number.should == 1

      petition_search = PetitionResults.new(options.merge(:page_number => '-1'))
      petition_search.page_number.should == 1
    end

    it "sets the arguments to new attributes" do
      petition_search = PetitionResults.new(options)
      petition_search.search_term.should == options[:search_term]
      petition_search.state.should       == options[:state]
      petition_search.per_page.should    == options[:per_page]
      petition_search.sort.should        == options[:sort]
      petition_search.order.should       == options[:order]
    end


    it "fills in with sensible defaults with a blank search" do
      petition_search = PetitionResults.new(options.merge(:search_term => ""))
      petition_search.search_term.should    == ""
      petition_search.state.should == Petition::OPEN_STATE
      petition_search.per_page.should       == options[:per_page]
    end

    it "fills in with sensible defaults without a search argument" do
      options.delete(:search_term)
      petition_search = PetitionResults.new(options)

      petition_search.search_term.should    == ""
      petition_search.state.should == Petition::OPEN_STATE
      petition_search.per_page.should       == options[:per_page]
      petition_search.state_counts["open"].should == 0
    end

    it "doesn't try to search without a search_term" do
      options.delete(:search_term)
      searcher.should_not_receive(:execute)
      petition_search = PetitionResults.new(options)
      petition_search.petitions.should == []
    end
  end
end
