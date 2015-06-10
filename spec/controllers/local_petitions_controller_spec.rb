require 'rails_helper'

describe LocalPetitionsController, type: :controller do
  describe 'GET :index' do
    include ConstituencyApiHelpers::NetworkLevel

    context 'when a postcode is supplied' do
      let(:postcode) { 'SW1A 1aa' }
      let(:params) { { postcode: postcode } }

      context 'that can be found on the API' do
        let(:constituency_id) { FactoryGirl.generate(:constituency_id) }
        let(:constituency_name) { 'Cities of London and Westminster' }
        let(:mp_id) { FactoryGirl.generate(:mp_id) }
        let(:mp) { ConstituencyApi::Mp.new(mp_id, 'Emma Pee MP', 3.years.ago.to_date) }
        before { stub_constituency(postcode, constituency_id, constituency_name, mp_id: mp.id, mp_name: mp.name, mp_start_date: mp.start_date) }

        it 'exposes a constituency object for the postcode' do
          get :index, params
          constituency = assigns(:constituency)
          expect(constituency).to be_present
          expect(constituency).to eq ConstituencyApi::Constituency.new(constituency_id, constituency_name, mp)
        end

        it 'exposes the 3 most popular petitions in the constituency' do
          petitions = double
          expect(Petition).to receive(:popular_in_constituency).with(constituency_id, 3).and_return petitions

          get :index, params

          petitions = assigns(:petitions)
          expect(petitions).to be_present
          expect(petitions).to eq petitions
        end

        it 'responds successfully and renders the index template' do
          get :index, params
          expect(response).to be_success
          expect(response).to render_template 'local_petitions/index'
        end
      end

      shared_examples_for 'a local petitions controller that failed to lookup a constituency' do
        it 'exposes no constituency object' do
          get :index, params
          constituency = assigns(:constituency)
          expect(constituency).to be_nil
        end

        it 'responds successfully and renders the error template' do
          get :index, params
          expect(response).to be_success
          expect(response).to render_template 'local_petitions/constituency_lookup_failed'
        end
      end

      context 'that cannot be found on the API' do
        before { stub_no_constituencies(postcode) }
        it_behaves_like 'a local petitions controller that failed to lookup a constituency'
      end

      context 'but the API is down' do
        before { stub_broken_api }

        it_behaves_like 'a local petitions controller that failed to lookup a constituency'
      end
    end

    shared_examples_for 'a local petitions controller that does not try to lookup a constituency' do
      it 'does not communicate with the API' do
        expect(ConstituencyApi::Client).not_to receive(:constituencies)
        get :index, params
      end

      it 'responds successfully and renders the blank postcode template' do
        get :index, params
        expect(response).to be_success
        expect(response).to render_template 'local_petitions/no_postcode_provided'
      end
    end

    context 'when no postcode is supplied' do
      let(:params) { {} }

      it_behaves_like 'a local petitions controller that does not try to lookup a constituency'
    end

    context 'when a blank postcode is supplied' do
      let(:params) { {postcode: ' '} }

      it_behaves_like 'a local petitions controller that does not try to lookup a constituency'
    end
  end
end
