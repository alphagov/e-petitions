# == Schema Information
#
# Table name: trending_petitions
#
#  id                      :integer(4)      not null, primary key
#  petition_id             :integer(4)
#  signatures_in_last_hour :integer(4)      default(0)
#  created_at              :datetime
#  updated_at              :datetime
#

require 'rails_helper'

describe TrendingPetition do
  describe "signatures in last hour" do
    it "has a default value of zero" do
      TrendingPetition.new.signatures_in_last_hour.should == 0
    end
  end

  describe ".update_homepage_trends" do
    before(:each) do
      Petition.stub!(:last_hour_trending => [double(:id => 666, :signatures_in_last_hour => '100')])
    end

    it "fetches the trending petitions for the last hour" do
      Petition.should_receive(:last_hour_trending)
      TrendingPetition.update_homepage_trends
    end

    it "removes any existing trending petitions and replaces them" do
      TrendingPetition.create!(:petition_id => 12345, :signatures_in_last_hour => 500)

      TrendingPetition.update_homepage_trends
      TrendingPetition.all.size.should == 1
      TrendingPetition.first.petition_id.should == 666
      TrendingPetition.first.signatures_in_last_hour.should == 100
    end
  end
end
