require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
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
