require 'rails_helper'

RSpec.describe SharingHelper, type: :helper do
  let(:petition) { double(:petition, to_param: "100000", action: "Do something") }
  let(:headers) { helper.request.env }

  before do
    headers["HTTP_HOST"]   = "petition.parliament.uk"
    headers["HTTPS"]       = "on"
    headers["SERVER_PORT"] = 443
  end

  describe "#share_via_facebook_url" do
    it "generates a share via Facebook url" do
      expect(helper.share_via_facebook_url(petition)).to eq <<-URL.strip
        https://www.facebook.com/sharer/sharer.php?ref=responsive&u=https%3A%2F%2Fpetition.parliament.uk%2Fpetitions%2F100000
      URL
    end
  end

  describe "#share_via_email_url" do
    it "generates a share via email url" do
      expect(helper.share_via_email_url(petition)).to eq <<-URL.strip
        mailto:?body=https%3A%2F%2Fpetition.parliament.uk%2Fpetitions%2F100000&subject=Petition%3A%20Do%20something
      URL
    end
  end

  describe "#share_via_whatsapp_url" do
    it "generates a share via Whatsapp url" do
      expect(helper.share_via_whatsapp_url(petition)).to eq <<-URL.strip
        whatsapp://send?text=Petition%3A%20Do%20something%0Ahttps%3A%2F%2Fpetition.parliament.uk%2Fpetitions%2F100000
      URL
    end
  end
end
