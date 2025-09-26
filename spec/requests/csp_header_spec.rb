require 'rails_helper'

RSpec.describe "Content Security Policy header", type: :request do
  let(:config) { Rails.application.config }
  let(:nonce_generator) { config.content_security_policy_nonce_generator }

  subject { response.header["Content-Security-Policy"] }

  before do
    allow(nonce_generator).to receive(:call).and_return("wtZ9F3CSW+xgJk8yWMLk")

    get "/"
  end

  it "sets default-src to 'self'" do
    expect(subject).to match(/\Adefault-src 'self';/)
  end

  it "sets connect-src to 'self', https://*.google-analytics.com, https://*.analytics.google.com and https://*.googletagmanager.com" do
    expect(subject).to match(/connect-src 'self' https:\/\/\*\.google-analytics\.com https:\/\/\*\.analytics\.google\.com https:\/\/\*\.googletagmanager\.com;/)
  end

  it "sets frame-src to 'self', https://*.google-analytics.com and https://*.googletagmanager.com" do
    expect(subject).to match(/frame-src 'self' https:\/\/\*\.google-analytics\.com https:\/\/\*\.googletagmanager\.com;/)
  end

  it "sets img-src to 'self', https://*.google-analytics.com and https://*.googletagmanager.com" do
    expect(subject).to match(/img-src 'self' https:\/\/\*\.google-analytics\.com https:\/\/\*\.googletagmanager\.com;/)
  end

  it "sets script-src to 'self', https://*.googletagmanager.com and nonce-wtZ9F3CSW+xgJk8yWMLk" do
    expect(subject).to match(/script-src 'self' https:\/\/\*\.googletagmanager\.com 'nonce-wtZ9F3CSW\+xgJk8yWMLk';/)
  end

  it "sets style-src to 'self' and 'unsafe-inline'" do
    expect(subject).to match(/style-src 'self' 'unsafe-inline' 'nonce-wtZ9F3CSW\+xgJk8yWMLk';/)
  end

  it "sets style-src-attr to 'self' and 'unsafe-inline'" do
    expect(subject).to match(/style-src-attr 'self' 'unsafe-inline'\z/)
  end
end
