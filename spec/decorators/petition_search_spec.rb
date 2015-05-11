require 'rails_helper'

describe PetitionSearch do
  let!(:open_petition_first) { FactoryGirl.create(:open_petition, title: 'First open petition') }
  let!(:open_petition_second) { FactoryGirl.create(:open_petition, title: 'Second open petition', description: 'Wombles again') }

  let!(:closed_petition_first) { FactoryGirl.create(:closed_petition, title: 'First closed petition', created_at: Time.now - 3.days) }
  let!(:closed_petition_second) { FactoryGirl.create(:closed_petition, title: 'Second closed petition', created_at: Time.now - 2.days) }
  let!(:closed_petition_third) { FactoryGirl.create(:closed_petition, title: 'Third closed petition', created_at: Time.now - 1.days) }

  let!(:rejected_petition_first) { FactoryGirl.create(:rejected_petition, title: 'First rejected petition') }

  before do
    if Petition.respond_to?(:reindex)
      Petition.reindex
    end
  end

  describe 'general search functionality' do
    it 'returns all petitions (matching the state) with empty search term' do
      search_params = { q: '', page: 1, state: 'open'}
      expect(PetitionSearch.new(search_params)).to match_array([open_petition_first, open_petition_second])
    end

    it 'matches the search term in petition title' do
      search_params = { q: 'First', page: 1, state: 'open' }
      expect(PetitionSearch.new(search_params)).to match_array([open_petition_first])
    end

    it 'matches the search term in petition description' do
      search_params = { q: 'Wombles', page: 1, state: 'open' }
      expect(PetitionSearch.new(search_params)).to match_array([open_petition_second])
    end

    it 'is case insensitive' do
      search_params = { q: 'WOMBLES', page: 1, state: 'open' }
      expect(PetitionSearch.new(search_params)).to match_array([open_petition_second])
    end
  end

  describe 'filtering by state' do
    it 'filters by open state' do
      search_params = { q: 'petition', page: 1, state: 'open' }
      expect(PetitionSearch.new(search_params)).to match_array([open_petition_first, open_petition_second])
    end
    it 'filters by closed state' do
      search_params = { q: 'petition', page: 1, state: 'closed' }
      expect(PetitionSearch.new(search_params)).to match_array([closed_petition_first, closed_petition_second, closed_petition_third])
    end
    it 'filters by rejected state' do
      search_params = { q: 'petition', page: 1, state: 'rejected' }
      expect(PetitionSearch.new(search_params)).to match_array([rejected_petition_first])
    end
    it 'filters by open state if no state is given as a param' do
      search_params = { q: 'petition', page: 1 }
      expect(PetitionSearch.new(search_params)).to match_array([open_petition_first, open_petition_second])
    end
  end

  describe 'search result counts' do
    let(:petitions) { PetitionSearch.new(q: 'petition', page: 1) }

    it 'returns result count for open state' do
      expect(petitions.result_count_for_state('open')).to eq 2
    end
    it 'returns result count for closed state' do
      expect(petitions.result_count_for_state('closed')).to eq 3
    end
    it 'returns result count for rejected state' do
      expect(petitions.result_count_for_state('rejected')).to eq 1
    end
  end

  describe 'search result ordering' do
    it 'can sort results by petition title ascending' do
      search_params = { q: 'petition', page: 1, state: 'closed', sort: 'title', order: 'asc' }
      expect(PetitionSearch.new(search_params).to_a).to eq([closed_petition_first, closed_petition_second, closed_petition_third])
    end
    it 'can sort results by petition title descending' do
      search_params = { q: 'petition', page: 1, state: 'closed', sort: 'title', order: 'desc' }
      expect(PetitionSearch.new(search_params).to_a).to eq([closed_petition_third, closed_petition_second, closed_petition_first])
    end

    it 'can sort results by petition create date ascending' do
      search_params = { q: 'petition', page: 1, state: 'closed', sort: 'created', order: 'asc' }
      expect(PetitionSearch.new(search_params).to_a).to eq([closed_petition_first, closed_petition_second, closed_petition_third])
    end
    it 'can sort results by petition create date descending' do
      search_params = { q: 'petition', page: 1, state: 'closed', sort: 'created', order: 'desc' }
      expect(PetitionSearch.new(search_params).to_a).to eq([closed_petition_third, closed_petition_second, closed_petition_first])
    end
  end
end
