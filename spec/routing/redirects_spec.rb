require 'rails_helper'

RSpec.describe "trying to access", type: :routes do
  it "the old /departments page redirects to the home page" do
    expect(get "/departments").to permanently_redirect_to("https://petition.parliament.uk/")
  end

  it "the old /api page redirects to the home page" do
    expect(get "/api/petitions").to permanently_redirect_to("https://petition.parliament.uk/")
  end

  it "the old /privacy-policy page redirects to the new privacy page" do
    expect(get "/privacy-policy").to permanently_redirect_to("https://petition.parliament.uk/privacy")
  end

  it "the old /accessibility page redirects to the help page" do
    expect(get "/accessibility").to permanently_redirect_to("https://petition.parliament.uk/help")
  end

  it "the old /terms-and-conditions page redirects to the help page" do
    expect(get "/terms-and-conditions").to permanently_redirect_to("https://petition.parliament.uk/help")
  end

  it "the old /how-it-works page redirects to the help page" do
    expect(get "/how-it-works").to permanently_redirect_to("https://petition.parliament.uk/help")
  end

  it "the old /faq page redirects to the help page" do
    expect(get "/faq").to permanently_redirect_to("https://petition.parliament.uk/help")
  end

  it "the old /crown-copyright page redirects to the National Archives page" do
    expect(get "/crown-copyright").to permanently_redirect_to(
      "https://www.nationalarchives.gov.uk/information-management/our-services/crown-copyright.htm"
    )
  end
end
