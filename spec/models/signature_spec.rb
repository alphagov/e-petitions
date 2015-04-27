# == Schema Information
#
# Table name: signatures
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)     not null
#  state            :string(10)      default("pending"), not null
#  perishable_token :string(255)
#  postcode         :string(255)
#  country          :string(255)
#  ip_address       :string(20)
#  petition_id      :integer(4)
#  created_at       :datetime
#  updated_at       :datetime
#  notify_by_email  :boolean(1)      default(FALSE)
#  last_emailed_at  :datetime
#  encrypted_email  :string(255)
#

require 'spec_helper'

describe Signature do
  it "should have a valid factory" do
    Factory.build(:signature).should be_valid
  end

  context "defaults" do
    it "state should default to pending" do
      s = Signature.new
      s.state.should == "pending"
    end

    it "perishable token should be populated by a call to friendly_token" do
      Authlogic::Random.should_receive(:friendly_token)
      Factory.create(:signature)
    end

    it "perishable token should not be nil" do
      s = Factory.create(:signature, :perishable_token => nil)
      s.perishable_token.should_not be_nil
    end

    it "should set notify_by_email to false" do
      s = Signature.new
      s.notify_by_email.should be_false
    end
  end

  context "encryption of email" do
    let(:signature) { Factory.create(:signature, :email => "foo@example.net") }
    it "transparently alters the email" do
      Signature.find(signature.id).email.should == "foo@example.net"
    end

    it "take no notice of the case" do
      Factory.build(:signature, :email => "FOO@exAmplE.net").encrypted_email.should == signature.encrypted_email
    end

    it "for_email takes into account the encrypted email" do
      Signature.for_email("foo@example.net").should == [signature]
    end
  end


  RSpec::Matchers.define :have_valid do |field|
    match do |actual|
      actual.errors_on(field).should be_blank
    end
  end

  context "validations" do
    it { should validate_presence_of(:name).with_message(/must be completed/) }
    it { should validate_presence_of(:email).with_message(/must be completed/) }
    it { should validate_presence_of(:address).with_message(/must be completed/) }
    it { should validate_presence_of(:town).with_message(/must be completed/) }
    it { should validate_presence_of(:country).with_message(/must be completed/) }
    it { should ensure_length_of(:name).is_at_most(255) }

    it "should validate format of email" do
      s = Factory.build(:signature, :email => 'joe@example.com')
      s.should have_valid(:email)
    end

    it "should not allow invalid email" do
      s = Factory.build(:signature, :email => 'not an email')
      s.should_not have_valid(:email)
    end

    describe "email confirmation" do
      it "require email confirmation on create" do
        s = Factory.build(:signature, :email => 'joe@example.com', :email_confirmation => nil)
        s.valid?
        s.errors_on(:email_confirmation).should_not be_blank
      end

      it "not require email confirmation on update" do
        s = Factory(:signature)
        s.update_attributes(:email => 'john@hotmail.com', :email_confirmation => nil).should be_true
      end

      it "require email and email confirmation to be the same" do
        s = Factory.build(:signature, :email => 'john@hotmail.com', :email_confirmation => 'john2@hotmail.com')
        s.valid?
        s.errors_on(:email).should_not be_blank
      end
    end

    describe "uniqueness of email" do
      before do
        Factory.create(:signature, :name => "Suzy Signer",
                       :petition_id => 1, :postcode => "sw1a 1aa",
                       :email => 'foo@example.com')
      end

      it "allows a second email to be used" do
        s = Factory.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        s.should have_valid(:email)
      end

      it "does not allow a third email to be used" do
        Factory.create(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        s = Factory.build(:signature, :name => "Sarah Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        s.should_not have_valid(:email)
      end

      it "does not allow the second email if the name is the same" do
        s = Factory.build(:signature, :name => "Suzy Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        s.should_not have_valid(:email)
      end

      it "ignores extra whitespace on name" do
        s = Factory.build(:signature, :name => "Suzy Signer ",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        s.should_not have_valid(:email)
        s = Factory.build(:signature, :name => " Suzy Signer",
                          :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'foo@example.com')
        s.should_not have_valid(:email)
      end

      it "only allows the second email if the postcode is the same" do
        s = Factory.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1ab',
                          :email => 'foo@example.com')
        s.should_not have_valid(:email)
      end

      it "ignores the space on the postcode check" do
        s = Factory.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a1aa',
                          :email => 'foo@example.com')
        s.should have_valid(:email)
        s = Factory.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a1ab',
                          :email => 'foo@example.com')
        s.should_not have_valid(:email)
      end

      it "does a case insensitive postcode check" do
        s = Factory.build(:signature, :name => "Sam Signer",
                          :petition_id => 1, :postcode => 'sw1a 1Aa',
                          :email => 'foo@example.com')
        s.should have_valid(:email)
      end

      it "is case insensitive about the subsequent validations" do
        s = Factory.create(:signature, :petition_id => 1, :postcode => 'sw1a 1aa',
                      :email => 'fOo@Example.com')
        s.should have_valid(:email)
        s = Factory.build(:signature, :petition_id => 1, :postcode => 'sw1a 1aa',
                          :email => 'FOO@Example.com')
        s.should_not have_valid(:email)
      end

      it "is scoped to petition" do
        s = Factory.build(:signature, :petition_id => 2, :email => 'foo@example.com')
        s.should have_valid(:email)
      end
    end

    it "should not allow blank or unknown state" do
      s = Factory.build(:signature, :state => '')
      s.should_not have_valid(:state)
      s.state = 'unknown'
      s.should_not have_valid(:state)
    end

    it "should allow known states" do
      s = Factory.build(:signature)
      %w(pending validated ).each do |state|
        s.state = state
        s.should have_valid(:state)
      end
    end

    describe "postcode" do
      it "requires a postcode for a UK address" do
        Factory.build(:signature, :postcode => 'SW1A 1AA').should be_valid
        Factory.build(:signature, :postcode => '').should_not be_valid
      end

      it "does not require a postcode for non-UK addresses" do
        Factory.build(:signature, :country => "United Kingdom", :postcode => '').should_not be_valid
        Factory.build(:signature, :country => "United States", :postcode => '').should be_valid
      end
    end

    describe "post district" do
      it "is the first half of the postcode" do
        Signature.new(:postcode => "SW1A 1AA").postal_district.should == "SW1A"
        Signature.new(:postcode => "E5C 2PL").postal_district.should == "E5C"
        Signature.new(:postcode => "E5 2PL").postal_district.should == "E5"
        Signature.new(:postcode => "E52 2PL").postal_district.should == "E52"
        Signature.new(:postcode => "SO22 2PL").postal_district.should == "SO22"
      end

      it "handles the lack of spaces" do
        Signature.new(:postcode => "SO222PL").postal_district.should == "SO22"
      end

      it "handles lack of spaces for shorter codes" do
        Signature.new(:postcode => "wn88en").postal_district.should == "WN8"
        Signature.new(:postcode => "hd58tf").postal_district.should == "HD5"
      end

      it "handles case correctly" do
        Signature.new(:postcode => "So222pL").postal_district.should == "SO22"
      end

      it "is blank for non-standard postcodes" do
        Signature.new(:postcode => "").postal_district.should == ""
        Signature.new(:postcode => "BFPO 1234").postal_district.should == ""
      end
    end

    describe "uk_citizenship" do
      it "should require acceptance of uk_citizenship for a new record" do
        Factory.build(:signature, :uk_citizenship => '1').should be_valid
        Factory.build(:signature, :uk_citizenship => '0').should_not be_valid
        Factory.build(:signature, :uk_citizenship => nil).should_not be_valid
      end

      it "should not require acceptance of uk_citizenship for old records" do
        sig = Factory.create(:signature)
        sig.reload
        sig.uk_citizenship = '0'
        sig.should be_valid
      end
    end

    describe "humanity" do
      it "should require acceptance of humanity for a new record" do
        Factory.build(:signature, :humanity => true).should be_valid
        Factory.build(:signature, :humanity => false).should_not be_valid
        Factory.build(:signature, :humanity => nil).should_not be_valid
      end

      it "should not require acceptance of humanity for old records" do
        sig = Factory.create(:signature)
        sig.reload
        sig.humanity = false
        sig.should be_valid
      end
    end

    describe "Terms and Conditions" do
      it "should require acceptance of terms_and_conditions for a new record" do
        Factory.build(:signature, :terms_and_conditions => '1').should be_valid
        Factory.build(:signature, :terms_and_conditions => '0').should_not be_valid
        Factory.build(:signature, :terms_and_conditions => nil).should_not be_valid
      end

      it "should not require acceptance of terms_and_conditions for old records" do
        sig = Factory.create(:signature)
        sig.reload
        sig.terms_and_conditions = '0'
        sig.should be_valid
      end
    end
  end

  context "scopes" do
    let(:week_ago) { 1.week.ago }
    let(:two_days_ago) { 2.days.ago }
    let!(:petition) { Factory(:petition) }
    let!(:signature1) { Factory.create(:signature, :email => "person1@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :last_emailed_at => nil) }
    let!(:signature2) { Factory.create(:signature, :email => "person2@example.com", :petition => petition, :state => Signature::PENDING_STATE, :last_emailed_at => two_days_ago) }
    let!(:signature3) { Factory.create(:signature, :email => "person3@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :last_emailed_at => week_ago) }
    let!(:signature4) { Factory.create(:signature, :email => "person4@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :last_emailed_at => two_days_ago) }
    let!(:signature5) { Factory.create(:signature, :email => "person5@example.com", :petition => petition, :state => Signature::VALIDATED_STATE, :notify_by_email => false, :last_emailed_at => two_days_ago) }

    context "validated" do
      it "should return only validated signatures" do
        signatures = Signature.validated
        signatures.size.should == 5
        signatures.should include(signature1, signature3, signature4, signature5, petition.creator_signature)
      end
    end

    context "need emailing" do
      it "should return only validated signatures who have opted in to receiving email updates" do
        Signature.need_emailing(Time.now).should include(signature1, signature3, signature4, petition.creator_signature)
        Signature.need_emailing(two_days_ago).should include(signature1, signature3, petition.creator_signature)
        Signature.need_emailing(week_ago).should include(signature1, petition.creator_signature)
      end
    end

    describe "for_email" do
      let!(:other_petition) { Factory(:petition) }
      let!(:other_signature) do
        Factory.create(:signature, :email => "person3@example.com",
        :petition => other_petition, :state => Signature::PENDING_STATE,
        :last_emailed_at => two_days_ago)
      end

      it "returns an empty set if the email is not found" do
        Signature.for_email("notfound@example.com").should == []
      end

      it "returns only signatures for the given email address" do
        Signature.for_email("person3@example.com").should ==
          [signature3, other_signature]
      end
    end

    describe "checking whether the signature is the creator" do
      let!(:petition) { Factory(:petition) }
      it "is the creator if the signature is listed as the creator signature" do
        petition.creator_signature.should be_creator
      end

      it "is not the creator if the signature is not listed as the creator" do
        signature = Factory(:signature, :petition => petition)
        signature.should_not be_creator
      end
    end
  end

  describe "#pending?" do
    it "returns true if the signature has a pending state" do
      signature = Factory.build(:pending_signature)
      signature.pending?.should be_true
    end

    it "returns false if the signature is validated state" do
      signature = Factory.build(:validated_signature)
      signature.pending?.should be_false
    end
  end
end
