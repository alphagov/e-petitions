require 'rails_helper'

describe DateTimeHelper do

  describe "local_date_time" do
    it "displays nothing if the date is nil" do
      helper.local_date_time_format(nil).should be_nil
    end

    it "displays a GMT time in winter" do
      date_time = DateTime.parse("17:45 25th December 2012")
      helper.local_date_time_format(date_time).should == "25/12/2012 17:45"
    end

    it "displays the BST time in summer" do
      date_time = DateTime.parse("17:45 15th June 2012")
      helper.local_date_time_format(date_time).should == "15/06/2012 18:45"
    end
  end

  describe "last_updated_at_time" do
    it "returns nil when no date" do
      helper.last_updated_at_time(nil).should == nil
    end

    it "returns just the time" do
      date_time = DateTime.parse("17:45 25th December 2012")
      helper.last_updated_at_time(date_time).should == "17:45 GMT"
    end

    it "returns just the time" do
      date_time = DateTime.parse("17:45 25th July 2012 GMT")
      helper.last_updated_at_time(date_time).should == "18:45 BST"
    end
  end

end
