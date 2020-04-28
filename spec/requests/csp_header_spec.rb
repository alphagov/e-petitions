require 'rails_helper'

RSpec.describe "Content Security Policy header", type: :request do
  subject { response.header["Content-Security-Policy"] }

  it "sets default-src to 'self'" do
    get "/"
    expect(subject).to match(/\Adefault-src 'self';/)
  end

  it "sets font-src to 'self' https://fonts.gstatic.com" do
    get "/"
    expect(subject).to match(/font-src 'self' https:\/\/fonts\.gstatic\.com;/)
  end

  it "sets img-src to 'self' data: https://www.google-analytics.com" do
    get "/"
    expect(subject).to match(/img-src 'self' data: https:\/\/www\.google-analytics\.com;/)
  end

  it "sets connect-src to 'self' https://apikeys.civiccomputing.com https://www.google-analytics.com" do
    get "/"
    expect(subject).to match(/connect-src 'self' https:\/\/apikeys\.civiccomputing\.com https:\/\/www\.google-analytics\.com;/)
  end

  it "sets script-src to 'self' 'unsafe-inline' https://cc.cdn.civiccomputing.com https://www.googletagmanager.com https://www.google-analytics.com" do
    get "/"
    expect(subject).to match(/script-src 'self' 'unsafe-inline' https:\/\/cc\.cdn\.civiccomputing\.com https:\/\/www\.googletagmanager\.com https:\/\/www\.google-analytics\.com;/)
  end

  it "sets style-src to 'self' 'unsafe-inline' https://fonts.googleapis.com" do
    get "/"
    expect(subject).to match(/style-src 'self' 'unsafe-inline' https:\/\/fonts\.googleapis\.com\z/)
  end

  context "when language editing is enabled" do
    before do
      allow(Site).to receive(:translation_enabled?).and_return(true)
    end

    it "includes the moderation site in the script-src directive" do
      get "/"
      expect(subject).to match(/script-src 'self' 'unsafe-inline' https:\/\/cc\.cdn\.civiccomputing\.com https:\/\/www\.googletagmanager\.com https:\/\/www\.google-analytics\.com https:\/\/moderate\.petitions\.senedd\.wales;/)
    end
  end
end
