require 'rails_helper'

RSpec.describe 'redirect for old pages', type: :request do
  it 'redirects to home page if trying to access old /departments page' do
    get '/departments'
    expect(response).to redirect_to('https://petition.parliament.uk/')
    expect(response.status).to eq 301
  end

  it 'redirects to home page if trying to access old /api page' do
    get '/api/petitions'
    expect(response).to redirect_to('https://petition.parliament.uk/')
    expect(response.status).to eq 301
  end

  it 'redirects to privacy page if trying to access old /privacy-policy page' do
    get '/privacy-policy'
    expect(response).to redirect_to('https://petition.parliament.uk/privacy')
    expect(response.status).to eq 301
  end

  it 'redirects redirects to help page if trying to access old /accessibility page' do
    get '/accessibility'
    expect(response).to redirect_to('https://petition.parliament.uk/help')
    expect(response.status).to eq 301
  end

  it 'redirects redirects to help page if trying to access old /terms-and-conditions page' do
    get '/terms-and-conditions'
    expect(response).to redirect_to('https://petition.parliament.uk/help')
    expect(response.status).to eq 301
  end

  it 'redirects to help page if trying to access old /how-it-works page' do
    get '/how-it-works'
    expect(response).to redirect_to('https://petition.parliament.uk/help')
    expect(response.status).to eq 301
  end

  it 'redirects to help page if trying to access old /faq page' do
    get '/faq'
    expect(response).to redirect_to('https://petition.parliament.uk/help')
    expect(response.status).to eq 301
  end

  it 'redirects to National Archives page if trying to access old /crown-copyright page' do
    get '/crown-copyright'
    expect(response).to redirect_to('https://www.nationalarchives.gov.uk/information-management/our-services/crown-copyright.htm')
    expect(response.status).to eq 301
  end
end
