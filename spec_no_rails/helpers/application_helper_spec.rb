require 'app/helpers/application_helper'

describe ApplicationHelper do
  include ApplicationHelper

  let(:request) { double(:request, :ssl? => false) }

  describe "http prefix" do
    it "defaults to http:// if no ssl" do
      http_prefix.should == 'http://'
    end
    it "switches to https:// if ssl is on" do
      request.stub(:ssl? => true)
      http_prefix.should == 'https://'
    end
  end
end
