require 'rails_helper'

RSpec.describe 'seen_cookie_message cookie', type: :request do
  subject { response.header["Set-Cookie"] }
  let(:one_year_from_now) { 1.year.from_now.getutc.rfc2822 }

  before do
    get "/"
  end

  it "should set the secure option" do
    expect(subject).to match(/; secure/i)
  end

  it "should set the httponly option" do
    expect(subject).to match(/; httponly/i)
  end

  it "should set the expiry to 1 year from now" do
    expect(subject).to match(/; expires=#{one_year_from_now}/)
  end
end
