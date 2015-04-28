require 'active_model'
require 'authlogic/regex'
require 'feedback'

describe Feedback do
  it "can be constructed without params" do
    Feedback.new.name.should be_nil
  end

  it "has a name" do
    Feedback.new(:name => 'foo').name.should == 'foo'
  end

  it "has an email" do
    Feedback.new(:email => 'foo').email.should == 'foo'
  end

  it "has an e-petition link or title" do
    Feedback.new(:petition_link_or_title => 'foo').petition_link_or_title.should == 'foo'
  end

  it "has a flag which determines whether a response is required" do
    Feedback.new(:response_required => '1').response_required.should be_true
    Feedback.new(:response_required => '0').response_required.should be_false
  end

  it "has a comment" do
    Feedback.new(:comment => 'foo').comment.should == 'foo'
  end

  def valid_attributes
    { :name => "Joe Public", :email => "foo@example.com", :email_confirmation => "foo@example.com",
      :comment => "I can't submit a petition for some reason", :petition_link_or_title => 'link' }
  end

  describe "valid?" do
    it "is valid when all attributes are in place" do
      Feedback.new(valid_attributes).should be_valid
    end

    it "is not valid when a required attribute is missing" do
      Feedback.new(valid_attributes.delete(:name)).should_not be_valid
      Feedback.new(valid_attributes.delete(:email)).should_not be_valid
      Feedback.new(valid_attributes.delete(:email_confirmation)).should_not be_valid
      Feedback.new(valid_attributes.delete(:comment)).should_not be_valid
    end

    it "requires an email confirmation" do
      feedback = Feedback.new(valid_attributes.merge({:email_confirmation => 'invalid'}))
      feedback.should_not be_valid
    end

    it "is not valid when the email format is wrong" do
      Feedback.new(valid_attributes.merge(:email => 'foo', :email_confirmation => 'foo')).should_not be_valid
    end
  end

end
