require 'rails_helper'

describe LocalPetitionsController, type: :controller do
  describe 'GET :index' do
    context 'when a postcode is supplied' do
      let(:postcode) { 'SW1A 1aa' }
      let(:params) { { postcode: postcode } }

      context 'that can be found on the API' do
        let(:api_url) { ConstituencyApi::Client::URL }
        let(:constituency_id) { FactoryGirl.generate(:constituency_id) }
        let(:constituency_name) { 'Cities of London and Westminster' }
        let(:mp) { ConstituencyApi::Mp.new('4321', 'Emma Pee MP', 3.years.ago.to_date) }
        let(:api_response) do
          <<-RESPONSE.strip_heredoc
            <Constituencies>
              <Constituency>
                <Constituency_Id>#{ constituency_id }</Constituency_Id>
                <Name>#{ constituency_name }</Name>
                <RepresentingMembers>
                  <RepresentingMember>
                    <Member_Id>#{mp.id}</Member_Id>
                    <Member>#{mp.name}</Member>
                    <StartDate>#{mp.start_date}</StartDate>
                    <EndDate xsi:nil="true"
                             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
                  </RepresentingMember>
                </RepresentingMembers>
              </Constituency>
            </Constituencies>
          RESPONSE
        end

        before do
          stub_request(:get, "#{ api_url }/#{PostcodeSanitizer.call(postcode)}/").to_return(status: 200, body: api_response)
        end

        it 'exposes a constituency object for the postcode' do
          get :index, params
          constituency = assigns(:constituency)
          expect(constituency).to be_present
          expect(constituency).to eq ConstituencyApi::Constituency.new(constituency_id, constituency_name, mp)
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
        let(:api_url) { ConstituencyApi::Client::URL }
        let(:api_response) do
          <<-RESPONSE.strip_heredoc
            <Constituencies/>
          RESPONSE
        end

        before do
          stub_request(:get, "#{ api_url }/#{PostcodeSanitizer.call(postcode)}/").to_return(status: 200, body: api_response)
        end

        it_behaves_like 'a local petitions controller that failed to lookup a constituency'
      end

      context 'but the API is down' do
        let(:api_url) { ConstituencyApi::Client::URL }
        before do
          stub_request(:get, "#{ api_url }/#{PostcodeSanitizer.call(postcode)}/").to_return(status: 500)
        end

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
