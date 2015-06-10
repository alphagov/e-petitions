require 'rails_helper'

describe SearchHelper do
 include SearchHelper

 describe "#petition_search_lists" do
   let(:params) { { controller: 'petitions' } }
   let(:petition_search) { double('petition_search') }

   it 'renders lists for searchable states' do
     allow(petition_search).to receive(:result_count_for_state).with(Petition::OPEN_STATE) { 10000 }
     allow(petition_search).to receive(:result_count_for_state).with(Petition::CLOSED_STATE) { 500 }
     allow(petition_search).to receive(:result_count_for_state).with(Petition::REJECTED_STATE) { 0 }

     search_lists_markup = petition_search_lists(petition_search, params)

     expect(search_lists_markup).to match(/Open \(10,000\)/)
     expect(search_lists_markup).to match(/Closed \(500\)/)
     expect(search_lists_markup).to match(/Rejected \(0\)/)
   end
 end
end
