require 'rails_helper'

RSpec.describe 'signed tokens cookie', type: :request, show_exceptions: true do
  let(:date) { Time.utc(2016, 4, 12, 12, 59, 59) }
  let(:cookies) { response.header["Set-Cookie"].split("\n") }

  subject do
    cookies.find{ |c| c =~ /^signed_tokens/ }
  end

  before do
    petition = FactoryBot.create(:open_petition)
    signature = FactoryBot.create(:pending_signature, petition: petition)

    get "/signatures/#{signature.id}/verify?token=#{signature.perishable_token}"
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

  it "should set the samesite=lax option" do
    expect(subject).to match(/; samesite=lax/i)
  end

  it "should not set any expiry" do
    expect(subject).not_to match(/; expires/)
  end
end
