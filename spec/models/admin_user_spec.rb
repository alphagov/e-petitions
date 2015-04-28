# == Schema Information
#
# Table name: admin_users
#
#  id                   :integer(4)      not null, primary key
#  email                :string(255)     not null
#  persistence_token    :string(255)
#  crypted_password     :string(255)
#  password_salt        :string(255)
#  login_count          :integer(4)      default(0)
#  failed_login_count   :integer(4)      default(0)
#  current_login_at     :datetime
#  last_login_at        :datetime
#  current_login_ip     :string(255)
#  last_login_ip        :string(255)
#  first_name           :string(255)
#  last_name            :string(255)
#  role                 :string(10)      not null
#  force_password_reset :boolean(1)      default(TRUE)
#  password_changed_at  :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

require 'spec_helper'

describe AdminUser do
  
  context "behaviours" do
    it { AdminUser.respond_to?(:acts_as_authentic).should be_true }    
  end
  
  context "defaults" do
    it "force_password_reset should default to true" do
      u = AdminUser.new
      u.force_password_reset.should be_true
    end
  end
  
  context "validations" do
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:first_name) }    
    it { should validate_presence_of(:last_name) }      
    it { should ensure_length_of(:password).is_at_least(8) }
    it { should allow_value("oliver@opsb.co.uk").for(:email)}
    it { should_not allow_value("jimbo").for(:email) }    
    
    it "should validate uniqueness of email" do
      Factory.create(:admin_user, :role => 'sysadmin')
      should validate_uniqueness_of(:email)
      should_not validate_uniqueness_of(:email).case_insensitive
    end
    
    it "should only allow passwords with a digit, lower and upper case alpha and a special char" do
      ['Letmein1!', 'Letmein1_', '1Ab*aaaa'].each do |email|
        u = Factory.build(:admin_user, :password => email, :password_confirmation => email)
        u.should be_valid
      end
    end
    
    it "should not allow passwords without a digit, lower and upper case alpha and a special char" do
      ['Letmein1', 'hell$0123', '^%ttttFFFFF', 'KJDL_3444'].each do |email|
        u = Factory.build(:admin_user, :password => email, :password_confirmation => email)
        u.should_not be_valid
      end
    end
    
    it "should allow sysadmin role" do
      u = Factory.build(:admin_user, :role => 'sysadmin')
      u.should be_valid
    end
    
    it "should allow threshold role" do
      u = Factory.build(:admin_user, :role => 'threshold')
      u.should be_valid
    end

    it "should allow admin role" do
      u = Factory.build(:admin_user, :role => 'admin')
      u.should be_valid
    end
    
    it "should disallow other roles" do
      u = Factory.build(:admin_user, :role => 'unheard_of')
      u.should_not be_valid
    end
  end
  
  context "scopes" do
    before :each do
      @user1 = Factory(:admin_user, :first_name => 'John', :last_name => 'Kennedy')
      @user2 = Factory(:admin_user, :first_name => 'Hilary', :last_name => 'Clinton')
      @user3 = Factory(:sysadmin_user, :first_name => 'Ronald', :last_name => 'Reagan')
      @user4 = Factory(:threshold_user, :first_name => 'Bill', :last_name => 'Clinton')
    end
    
    context "by_name" do
      it "should return admin users by name" do
        AdminUser.by_name.should == [@user4, @user2, @user1, @user3]
      end
    end
    
    context "by_role" do
      it "should return admin users" do
        AdminUser.by_role(AdminUser::ADMIN_ROLE).size.should == 2
        AdminUser.by_role(AdminUser::ADMIN_ROLE).should include(@user1, @user2)
      end
      
      it "should return threshold users" do
        AdminUser.by_role(AdminUser::THRESHOLD_ROLE).should == [@user4]
      end
    end
  end
  
  context "methods" do
    it "should return a user's name" do
      Factory(:admin_user, :first_name => 'Jo', :last_name => 'Public').name.should == 'Public, Jo'
    end
    
    context "is_a_sysadmin?" do
      it "should return true when user is a sysadmin" do
        Factory(:admin_user, :role => 'sysadmin').is_a_sysadmin?.should be_true
      end
    
      it "should return false when user is a admin" do
        Factory(:admin_user, :role => 'admin').is_a_sysadmin?.should be_false
      end
    end

    context "is_a_threshold?" do
      it "should return true when user is a threshold user" do
        Factory(:admin_user, :role => 'threshold').is_a_threshold?.should be_true
      end
    
      it "should return false when user is a admin" do
        Factory(:admin_user, :role => 'admin').is_a_threshold?.should be_false
      end
    end
    
    context "has_to_change_password?" do
      it "should be true when force_reset_password is true" do
        Factory(:admin_user, :force_password_reset => true).has_to_change_password?.should be_true
      end
      
      it "should be false when force_reset_password is false" do
        Factory(:admin_user, :force_password_reset => false).has_to_change_password?.should be_false
      end

      it "should be true when password was last changed over 9 months ago" do
        user = Factory(:admin_user, :force_password_reset => false, :password_changed_at => 9.months.ago - 1.minute)
        user.has_to_change_password?.should be_true
      end
      
      it "should be false when password was last changed less than 9 months ago" do
        user = Factory(:admin_user, :force_password_reset => false, :password_changed_at => 9.months.ago + 1.minute)
        user.has_to_change_password?.should be_false
      end
    end

    context "can_take_petitions_down?" do
      it "should be false normally" do
        Factory(:admin_user, :role => 'admin').can_take_petitions_down?.should be_false
      end

      it "is true if the user is a sysadmin" do
        Factory(:admin_user, :role => 'sysadmin').can_take_petitions_down?.should be_true
      end

      it "is true if the user is a threshold user" do
        Factory(:admin_user, :role => 'threshold').can_take_petitions_down?.should be_true
      end
    end

    context "can_see_all_trending_petitions?" do
      it "is normally false" do
        Factory(:admin_user, :role => 'admin').can_see_all_trending_petitions?.should be_false
      end

      it "is true when the user is a system admin" do
        Factory(:admin_user, :role => 'sysadmin').can_see_all_trending_petitions?.should be_true
      end

      it "is true if the user is a threshold user" do
        Factory(:admin_user, :role => 'threshold').can_see_all_trending_petitions?.should be_true
      end

    end

    context "account_disabled" do
      it "should return true when user has tried to login 5 times unsuccessfully" do
        user = Factory(:admin_user)
        user.failed_login_count = 5
        user.account_disabled.should be_true
      end
      
      it "should return true when user has tried to login 6 times unsuccessfully" do
        user = Factory(:admin_user)
        user.failed_login_count = 6
        user.account_disabled.should be_true
      end
    
      it "should return false when user has tried to login 4 times unsuccessfully" do
        user = Factory(:admin_user)
        user.failed_login_count = 4
        user.account_disabled.should be_false
      end
    end
    
    context "account_disabled=" do
      it "should set the failed login count to 5 when true" do
        u = Factory(:admin_user)
        u.account_disabled = true
        u.failed_login_count.should == 5
      end
      
      it "should set the failed login count to 0 when false" do
        u = Factory(:admin_user)
        u.failed_login_count = 5
        u.account_disabled = false
        u.failed_login_count.should == 0
      end
    end
  end
end
