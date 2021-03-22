require 'rails_helper'

RSpec.describe 'session cookie', type: :request, show_exceptions: true do
  let(:date) { Time.utc(2016, 4, 12, 12, 59, 59) }
  let(:cookies) { response.header["Set-Cookie"].split("\n") }

  subject do
    cookies.find{ |c| c =~ /^_wpets_session/ }
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

  it "should set the samesite option" do
    expect(subject).to match(/; samesite=strict/i)
  end

  it "should not set any expiry" do
    expect(subject).not_to match(/; expires/)
  end
end
