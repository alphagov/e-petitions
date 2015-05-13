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

require 'rails_helper'

describe AdminUser do

  context "behaviours" do
    it { expect(AdminUser.respond_to?(:acts_as_authentic)).to be_truthy }
  end

  context "defaults" do
    it "force_password_reset should default to true" do
      u = AdminUser.new
      expect(u.force_password_reset).to be_truthy
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to allow_value("oliver@opsb.co.uk").for(:email)}
    it { is_expected.not_to allow_value("jimbo").for(:email) }

    it "should validate uniqueness of email" do
      FactoryGirl.create(:admin_user, :role => 'sysadmin')
      is_expected.to validate_uniqueness_of(:email).case_insensitive
    end

    it "should only allow passwords with a digit, lower and upper case alpha and a special char" do
      ['Letmein1!', 'Letmein1_', '1Ab*aaaa'].each do |email|
        u = FactoryGirl.build(:admin_user, :password => email, :password_confirmation => email)
        expect(u).to be_valid
      end
    end

    it "should not allow passwords without a digit, lower and upper case alpha and a special char" do
      ['Letmein1', 'hell$0123', '^%ttttFFFFF', 'KJDL_3444'].each do |email|
        u = FactoryGirl.build(:admin_user, :password => email, :password_confirmation => email)
        expect(u).not_to be_valid
      end
    end

    it "should allow sysadmin role" do
      u = FactoryGirl.build(:admin_user, :role => 'sysadmin')
      expect(u).to be_valid
    end

    it "should allow threshold role" do
      u = FactoryGirl.build(:admin_user, :role => 'threshold')
      expect(u).to be_valid
    end

    it "should allow admin role" do
      u = FactoryGirl.build(:admin_user, :role => 'admin')
      expect(u).to be_valid
    end

    it "should disallow other roles" do
      u = FactoryGirl.build(:admin_user, :role => 'unheard_of')
      expect(u).not_to be_valid
    end
  end

  context "scopes" do
    before :each do
      @user1 = FactoryGirl.create(:admin_user, :first_name => 'John', :last_name => 'Kennedy')
      @user2 = FactoryGirl.create(:admin_user, :first_name => 'Hilary', :last_name => 'Clinton')
      @user3 = FactoryGirl.create(:sysadmin_user, :first_name => 'Ronald', :last_name => 'Reagan')
      @user4 = FactoryGirl.create(:threshold_user, :first_name => 'Bill', :last_name => 'Clinton')
    end

    context "by_name" do
      it "should return admin users by name" do
        expect(AdminUser.by_name).to eq([@user4, @user2, @user1, @user3])
      end
    end

    context "by_role" do
      it "should return admin users" do
        expect(AdminUser.by_role(AdminUser::ADMIN_ROLE).size).to eq(2)
        expect(AdminUser.by_role(AdminUser::ADMIN_ROLE)).to include(@user1, @user2)
      end

      it "should return threshold users" do
        expect(AdminUser.by_role(AdminUser::THRESHOLD_ROLE)).to eq([@user4])
      end
    end
  end

  context "methods" do
    it "should return a user's name" do
      user = FactoryGirl.create(:admin_user, :first_name => 'Jo', :last_name => 'Public')
      expect(user.name).to eq('Public, Jo')
    end

    context "is_a_sysadmin?" do
      it "should return true when user is a sysadmin" do
        user = FactoryGirl.create(:admin_user, :role => 'sysadmin')
        expect(user.is_a_sysadmin?).to be_truthy
      end

      it "should return false when user is a admin" do
        user = FactoryGirl.create(:admin_user, :role => 'admin')
        expect(user.is_a_sysadmin?).to be_falsey
      end
    end

    context "is_a_threshold?" do
      it "should return true when user is a threshold user" do
        user = FactoryGirl.create(:admin_user, :role => 'threshold')
        expect(user.is_a_threshold?).to be_truthy
      end

      it "should return false when user is a admin" do
        user = FactoryGirl.create(:admin_user, :role => 'admin')
        expect(user.is_a_threshold?).to be_falsey
      end
    end

    context "has_to_change_password?" do
      it "should be true when force_reset_password is true" do
        user = FactoryGirl.create(:admin_user, :force_password_reset => true)
        expect(user.has_to_change_password?).to be_truthy
      end

      it "should be false when force_reset_password is false" do
        user = FactoryGirl.create(:admin_user, :force_password_reset => false)
        expect(user.has_to_change_password?).to be_falsey
      end

      it "should be true when password was last changed over 9 months ago" do
        user = FactoryGirl.create(:admin_user, :force_password_reset => false, :password_changed_at => 9.months.ago - 1.minute)
        expect(user.has_to_change_password?).to be_truthy
      end

      it "should be false when password was last changed less than 9 months ago" do
        user = FactoryGirl.create(:admin_user, :force_password_reset => false, :password_changed_at => 9.months.ago + 1.minute)
        expect(user.has_to_change_password?).to be_falsey
      end
    end

    context "can_take_petitions_down?" do
      it "should be false normally" do
        user = FactoryGirl.create(:admin_user, :role => 'admin')
        expect(user.can_take_petitions_down?).to be_falsey
      end

      it "is true if the user is a sysadmin" do
        user = FactoryGirl.create(:admin_user, :role => 'sysadmin')
        expect(user.can_take_petitions_down?).to be_truthy
      end

      it "is true if the user is a threshold user" do
        user = FactoryGirl.create(:admin_user, :role => 'threshold')
        expect(user.can_take_petitions_down?).to be_truthy
      end
    end

    context "account_disabled" do
      it "should return true when user has tried to login 5 times unsuccessfully" do
        user = FactoryGirl.create(:admin_user)
        user.failed_login_count = 5
        expect(user.account_disabled).to be_truthy
      end

      it "should return true when user has tried to login 6 times unsuccessfully" do
        user = FactoryGirl.create(:admin_user)
        user.failed_login_count = 6
        expect(user.account_disabled).to be_truthy
      end

      it "should return false when user has tried to login 4 times unsuccessfully" do
        user = FactoryGirl.create(:admin_user)
        user.failed_login_count = 4
        expect(user.account_disabled).to be_falsey
      end
    end

    context "account_disabled=" do
      it "should set the failed login count to 5 when true" do
        u = FactoryGirl.create(:admin_user)
        u.account_disabled = true
        expect(u.failed_login_count).to eq(5)
      end

      it "should set the failed login count to 0 when false" do
        u = FactoryGirl.create(:admin_user)
        u.failed_login_count = 5
        u.account_disabled = false
        expect(u.failed_login_count).to eq(0)
      end
    end
  end
end
