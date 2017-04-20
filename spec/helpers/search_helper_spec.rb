require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  describe "#paginate" do
    let(:page_stubs) do
      {
        total_pages: 3,
        previous_link: "/petitions?page=1&state=all",
        next_link: "/petitions?state=all",
        model: Petition
      }
    end

    context "when viewing the first page of the petitions search results" do
      let(:first_page_stubs) do
        {
          first_page?: true,
          last_page?: false,
          previous_params: { state: :all, page: nil },
          next_params: { state: :all, page: 2 },
          previous_page: nil,
          next_page: 2,
        }
      end

      let(:petitions) { double('petitions', page_stubs.merge(first_page_stubs)) }

      it "adds a link to the next page" do
        expect(paginate(petitions)).to include "Next"
      end

      it "does not add a link to the previous page" do
        expect(paginate(petitions)).not_to include "Previous"
      end

      it "adds the correct number range for the next page" do
        expect(paginate(petitions)).to include "2 of 3"
      end
    end

    context "when viewing an intermediary page of the petitions search results" do
      let(:intermediary_page_stubs) do
        {
          first_page?: false,
          last_page?: false,
          previous_params: { state: :all, page: 1 },
          next_params: { state: :all, page: 3 },
          previous_page: 1,
          next_page: 3,
        }
      end

      let(:petitions) { double('petitions', page_stubs.merge(intermediary_page_stubs)) }

      it "adds a link to the next page" do
        expect(paginate(petitions)).to include "Next"
      end

      it "adds a link to the previous page" do
        expect(paginate(petitions)).to include "Previous"
      end

      it "adds the correct number range for the next page" do
        expect(paginate(petitions)).to include "3 of 3"
      end

      it "adds the correct number range for the previous page" do
        expect(paginate(petitions)).to include "1 of 3"
      end
    end

    context "when viewing the last page of the petitions search results" do
      let(:last_page_stubs) do
        {
          first_page?: false,
          last_page?: true,
          previous_params: { state: :all, page: 2 },
          next_params: { state: :all, page: nil },
          previous_page: 2,
          next_page: nil,
        }
      end

      let(:petitions) { double('petitions', page_stubs.merge(last_page_stubs)) }

      it "does not add a link to the next page" do
        expect(paginate(petitions)).not_to include "Next"
      end

      it "adds a link to the previous page" do
        expect(paginate(petitions)).to include "Previous"
      end

      it "adds the correct number range for the previous page" do
        expect(paginate(petitions)).to include "2 of 3"
      end
    end
  end

  describe "#filtered_petition_count" do
    context 'when search term is not present' do
      it 'renders correctly with > 1 results' do
        petitions = double('petitions', total_entries: 100, "search?" => false)
        expect(filtered_petition_count(petitions)).to eq("100 petitions")
      end
      it 'renders correctly with just 1 result' do
        petitions = double('petitions', total_entries: 1, "search?" => false)
        expect(filtered_petition_count(petitions)).to eq("1 petition")
      end
    end

    context 'when search term is present' do
      it 'renders correctly with > 1 results' do
        petitions = double('petitions', total_entries: 100, "search?" => true)
        expect(filtered_petition_count(petitions)).to eq("100 results")
      end
      it 'renders correctly with just 1 result' do
        petitions = double('petitions', total_entries: 1, "search?" => true)
        expect(filtered_petition_count(petitions)).to eq("1 result")
      end
    end
  end
end
