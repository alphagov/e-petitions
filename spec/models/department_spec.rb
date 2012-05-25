# == Schema Information
#
# Table name: departments
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)     not null
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  website_url :string(255)
#

require 'spec_helper'

describe Department do

  context "validations" do

    it { should validate_presence_of(:name) }

    it "should validate uniqueness of name" do
      Factory.create(:department)
      should validate_uniqueness_of(:name).case_insensitive
    end
  end

  context "scopes" do
    before :each do
      @d1 = Factory(:department, :name => 'Treasury')
      @d2 = Factory(:department, :name => 'DEFRA')
      @d3 = Factory(:department, :name => 'Ministry of Defence')
      @d4 = Factory(:department, :name => 'DFID')
    end

    context "by_name" do
      it "should return by name" do
       Department.by_name.should == [@d2, @d4, @d3, @d1]
      end
    end

    context "by_petition_count" do
      it "should return departments ordered by petition count descending" do
        5.times { Factory(:open_petition, :department => @d4)}
        2.times { Factory(:closed_petition, :department => @d3)}
        3.times { Factory(:pending_petition, :department => @d1)}
        Department.by_petition_count.should == [@d4, @d1, @d3]
      end
    end
  end
end
