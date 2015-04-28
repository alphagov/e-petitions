require 'active_model'
require 'authlogic/regex'
require 'feedback'

describe Feedback do
  it "can be constructed without params" do
    expect(Feedback.new.name).to be_nil
  end

  it "has a name" do
    expect(Feedback.new(:name => 'foo').name).to eq('foo')
  end

  it "has an email" do
    expect(Feedback.new(:email => 'foo').email).to eq('foo')
  end

  it "has an e-petition link or title" do
    expect(Feedback.new(:petition_link_or_title => 'foo').petition_link_or_title).to eq('foo')
  end

  it "has a flag which determines whether a response is required" do
    expect(Feedback.new(:response_required => '1').response_required).to be_truthy
    expect(Feedback.new(:response_required => '0').response_required).to be_falsey
  end

  it "has a comment" do
    expect(Feedback.new(:comment => 'foo').comment).to eq('foo')
  end

  def valid_attributes
    { :name => "Joe Public", :email => "foo@example.com", :email_confirmation => "foo@example.com",
      :comment => "I can't submit a petition for some reason", :petition_link_or_title => 'link' }
  end

  describe "valid?" do
    it "is valid when all attributes are in place" do
      expect(Feedback.new(valid_attributes)).to be_valid
    end

    it "is not valid when a required attribute is missing" do
      expect(Feedback.new(valid_attributes.except(:name))).not_to be_valid
      expect(Feedback.new(valid_attributes.except(:email))).not_to be_valid
      expect(Feedback.new(valid_attributes.except(:email_confirmation))).not_to be_valid
      expect(Feedback.new(valid_attributes.except(:comment))).not_to be_valid
    end

    it "requires an email confirmation" do
      feedback = Feedback.new(valid_attributes.merge({:email_confirmation => 'invalid'}))
      expect(feedback).not_to be_valid
    end

    it "is not valid when the email format is wrong" do
      expect(Feedback.new(valid_attributes.merge(:email => 'foo', :email_confirmation => 'foo'))).not_to be_valid
    end
  end

end
