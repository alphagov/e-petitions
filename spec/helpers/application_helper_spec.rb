require 'rails_helper'

describe ApplicationHelper do
  include ApplicationHelper

  let(:request) { double(:request, :ssl? => false) }

  describe "http prefix" do
    it "defaults to http:// if no ssl" do
      expect(http_prefix).to eq('http://')
    end
    it "switches to https:// if ssl is on" do
      allow(request).to receive_messages(:ssl? => true)
      expect(http_prefix).to eq('https://')
    end
  end
end
