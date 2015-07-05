require 'rails_helper'

RSpec.describe 'HSTS headers', type: :request do
  subject { response.header["Strict-Transport-Security"] }

  before do
    get "/"
  end

  it "sets the includeSubDomains option" do
    expect(subject).to match(/IncludeSubDomains/i)
  end

  it "sets the max-ago to 365 days" do
    expect(subject).to match(/max-age=31536000/i)
  end
end
