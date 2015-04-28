require 'rails_helper'

describe DateTimeHelper do

  describe "local_date_time" do
    it "displays nothing if the date is nil" do
      expect(helper.local_date_time_format(nil)).to be_nil
    end

    it "displays a GMT time in winter" do
      date_time = DateTime.parse("17:45 25th December 2012")
      expect(helper.local_date_time_format(date_time)).to eq("25/12/2012 17:45")
    end

    it "displays the BST time in summer" do
      date_time = DateTime.parse("17:45 15th June 2012")
      expect(helper.local_date_time_format(date_time)).to eq("15/06/2012 18:45")
    end
  end

  describe "last_updated_at_time" do
    it "returns nil when no date" do
      expect(helper.last_updated_at_time(nil)).to eq(nil)
    end

    it "returns just the time" do
      date_time = DateTime.parse("17:45 25th December 2012")
      expect(helper.last_updated_at_time(date_time)).to eq("17:45 GMT")
    end

    it "returns just the time" do
      date_time = DateTime.parse("17:45 25th July 2012 GMT")
      expect(helper.last_updated_at_time(date_time)).to eq("18:45 BST")
    end
  end

end
