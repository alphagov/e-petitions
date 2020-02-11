require 'rails_helper'

RSpec.describe "Content Security Policy header", type: :request do
  subject { response.header["Content-Security-Policy"] }

  before do
    get "/"
  end

  it "sets default-src to 'self'" do
    expect(subject).to match(/\Adefault-src 'self';/)
  end

  it "sets img-src to 'self' data:" do
    expect(subject).to match(/img-src 'self' data:;/)
  end

  it "sets script-src to 'self' and 'unsafe-inline'" do
    expect(subject).to match(/script-src 'self' 'unsafe-inline' https:\/\/moderate\.petition\.parliament\.wales;/)
  end

  it "sets style-src to 'self' and 'unsafe-inline'" do
    expect(subject).to match(/style-src 'self' 'unsafe-inline'\z/)
  end
end
