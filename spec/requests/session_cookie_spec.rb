require 'rails_helper'

RSpec.describe 'session cookie', type: :request, show_exceptions: true do
  let(:date) { Time.utc(2016, 4, 12, 12, 59, 59) }
  let(:cookies) { response.header["Set-Cookie"].split("\n") }

  subject do
    cookies.find{ |c| c =~ /^_epets_session/ }
  end

  before do
    petition = FactoryBot.create(:open_petition)
    get "/petitions/#{petition.id}/signatures/new"
  end

  around do |example|
    travel_to(date) { example.run }
  end

  it "should set the secure option" do
    expect(subject).to match(/; secure/i)
  end

  it "should set the httponly option" do
    expect(subject).to match(/; httponly/i)
  end

  it "should set the expiry to 2 weeks from now" do
    expect(subject).to match(/; expires=Tue, 26 Apr 2016 12:59:59 -0000/)
  end
end
