require 'rails_helper'

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
      allow(Search).to receive_messages(:new => searcher)
      allow(searcher).to receive_messages(:execute => search, :state_counts_for => counts)
      allow(search).to receive_messages(:results => petitions)
    end

    describe "searching" do
      it "creates the search object with the correct configuration" do
        expect(Search).to receive(:new).with(hash_including(
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
        expect(alternative_strategy).to receive(:new).and_return(searcher)
        PetitionResults.new(options.merge(:search_strategy => alternative_strategy))
      end

      it "queries the search subsystem" do
        expect(searcher).to receive(:execute).with(options[:search_term]).and_return(search)
        PetitionResults.new(options)
      end

      it "asks the search server for petitions" do
        petition_search = PetitionResults.new(options)
        expect(petition_search.petitions).to eq(petitions)
      end

      it "sets the state counts" do
        petition_search = PetitionResults.new(options)
        expect(petition_search.state_counts).to eq(counts)
      end
    end

    it "defaults the state to open" do
      options.delete(:state)
      petition_search = PetitionResults.new(options)
      expect(petition_search.state).to eq(Petition::OPEN_STATE)
    end

    it "converts the page number to an integer" do
      petition_search = PetitionResults.new(options)
      expect(petition_search.page_number).to eq(3)
    end

    it "always returns at least a page number of 1" do
      options.delete(:page_number)
      petition_search = PetitionResults.new(options)
      expect(petition_search.page_number).to eq(1)

      petition_search = PetitionResults.new(options.merge(:page_number => '-1'))
      expect(petition_search.page_number).to eq(1)
    end

    it "sets the arguments to new attributes" do
      petition_search = PetitionResults.new(options)
      expect(petition_search.search_term).to eq(options[:search_term])
      expect(petition_search.state).to       eq(options[:state])
      expect(petition_search.per_page).to    eq(options[:per_page])
      expect(petition_search.sort).to        eq(options[:sort])
      expect(petition_search.order).to       eq(options[:order])
    end


    it "fills in with sensible defaults with a blank search" do
      petition_search = PetitionResults.new(options.merge(:search_term => ""))
      expect(petition_search.search_term).to    eq("")
      expect(petition_search.state).to eq(Petition::OPEN_STATE)
      expect(petition_search.per_page).to       eq(options[:per_page])
    end

    it "fills in with sensible defaults without a search argument" do
      options.delete(:search_term)
      petition_search = PetitionResults.new(options)

      expect(petition_search.search_term).to    eq("")
      expect(petition_search.state).to eq(Petition::OPEN_STATE)
      expect(petition_search.per_page).to       eq(options[:per_page])
      expect(petition_search.state_counts["open"]).to eq(0)
    end

    it "doesn't try to search without a search_term" do
      options.delete(:search_term)
      expect(searcher).not_to receive(:execute)
      petition_search = PetitionResults.new(options)
      expect(petition_search.petitions).to eq([])
    end
  end
end
