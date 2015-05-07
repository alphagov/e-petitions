require 'rails_helper'

describe SponsorsController do
  context 'GET show' do
    let(:petition) { FactoryGirl.create(:petition) }
    let(:sponsor) { FactoryGirl.create(:sponsor, petition: petition) }

    it 'fetches the requested petition' do
      get :show, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:petition]).to eq petition
    end

    it 'fetches the requested sponsor by the token' do
      get :show, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:sponsor]).to eq sponsor
    end

    # TODO: check for invalid petition states?
    it '404s if the requested petition does not exist' do
      petition_param = petition.to_param
      petition.destroy
      expect {
        get :show, petition_id: petition_param, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token does not exist' do
      expect {
        get :show, petition_id: petition, token: 'not-a-real-sponsor-perishable-token'
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it '404s if the requested sponsor token belongs to a different petition' do
      petition_2 = FactoryGirl.create(:petition)
      expect {
        get :show, petition_id: petition_2, token: sponsor.perishable_token
      }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'builds a signature for the sponsor' do
      get :show, petition_id: petition, token: sponsor.perishable_token
      expect(assigns[:signature]).to be_present
      expect(assigns[:signature].petition).to eq sponsor.petition
      expect(assigns[:signature].email).to eq sponsor.email
    end
  end
end
