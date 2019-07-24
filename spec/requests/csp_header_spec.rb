require 'rails_helper'

RSpec.describe "Content Security Policy header", type: :request do
  subject { response.header["Content-Security-Policy"] }

  before do
    get "/"
  end

  it "sets default-src to 'self'" do
    expect(subject).to match(/\Adefault-src 'self';/)
  end

  it "sets script-src to 'self', 'unsafe-inline' and www.googletagmanager.com" do
    expect(subject).to match(/script-src 'self' 'unsafe-inline' www\.googletagmanager\.com;/)
  end

  it "sets style-src to 'self' and 'unsafe-inline'" do
    expect(subject).to match(/style-src 'self' 'unsafe-inline'\z/)
  end
end
