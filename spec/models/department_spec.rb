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

require 'rails_helper'

describe Department do

  context "validations" do

    it { should validate_presence_of(:name) }

    it "should validate uniqueness of name" do
      FactoryGirl.create(:department)
      should validate_uniqueness_of(:name).case_insensitive
    end
  end

  context "scopes" do
    before :each do
      @d1 = FactoryGirl.create(:department, :name => 'Treasury')
      @d2 = FactoryGirl.create(:department, :name => 'DEFRA')
      @d3 = FactoryGirl.create(:department, :name => 'Ministry of Defence')
      @d4 = FactoryGirl.create(:department, :name => 'DFID')
    end

    context "by_name" do
      it "should return by name" do
       Department.by_name.should == [@d2, @d4, @d3, @d1]
      end
    end

    context "by_petition_count" do
      it "should return departments ordered by petition count descending" do
        5.times { FactoryGirl.create(:open_petition, :department => @d4)}
        2.times { FactoryGirl.create(:closed_petition, :department => @d3)}
        3.times { FactoryGirl.create(:pending_petition, :department => @d1)}
        Department.by_petition_count.should == [@d4, @d1, @d3]
      end
    end
  end
end
