require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do

  describe "#paginate" do

    let (:page_params) {{
      :total_pages=>3,
      :previous_link=>"/petitions?page=1&state=all",
      :next_link=>"/petitions?state=all",
      "model" => Petition
    }}

    let (:first_page_params) {{
      "first_page?" => true,
      "last_page?" => false,
      "previous_params" => {:state=>:all, :page=>nil},
      "next_params" => {:state=>:all, :page=>2},
      :previous_page=>nil,
      :next_page=>2,
    }}

    let (:intermediary_page_params) {{
      "first_page?" => false,
      "last_page?" => false,
      "previous_params" => {:state=>:all, :page=>1},
      "next_params" => {:state=>:all, :page=>3},
      :previous_page=>1,
      :next_page=>2,
    }}

    let (:last_page_params) {{
      "first_page?" => false,
      "last_page?" => true,
      "previous_params" => {:state=>:all, :page=>2},
      "next_params" => {:state=>:all, :page=>nil},
      :previous_page=>2,
      :next_page=>nil,
    }}

    context "when it handles the first page of petitions" do
      it "only adds a link to the next page" do
        petitions = double('petitions', page_params.merge(first_page_params))
        expect(paginate(petitions)).to include "Next"
        expect(paginate(petitions)).not_to include "Previous"
      end
    end

    context "when it handles an intermediary page of petitions" do
      it "adds both pagination links" do
        petitions = double('petitions', page_params.merge(intermediary_page_params))
        expect(paginate(petitions)).to include "Next"
        expect(paginate(petitions)).to include "Previous"
      end
    end

    context "when it handles the last page of petitions" do
      it "only adds a link to the previous page" do
        petitions = double('petitions', page_params.merge(last_page_params))
        expect(paginate(petitions)).to include "Previous"
        expect(paginate(petitions)).not_to include "Next"
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
