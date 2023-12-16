require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:email).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:persistence_token).of_type(:string) }
    it { is_expected.to have_db_column(:encrypted_password).of_type(:string) }
    it { is_expected.to have_db_column(:password_salt).of_type(:string) }
    it { is_expected.to have_db_column(:sign_in_count).of_type(:integer).with_options(default: 0) }
    it { is_expected.to have_db_column(:failed_attempts).of_type(:integer).with_options(default: 0) }
    it { is_expected.to have_db_column(:current_sign_in_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:last_sign_in_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:current_sign_in_ip).of_type(:string) }
    it { is_expected.to have_db_column(:last_sign_in_ip).of_type(:string) }
    it { is_expected.to have_db_column(:role).of_type(:string).with_options(limit: 10, null: false) }
    it { is_expected.to have_db_column(:force_password_reset).of_type(:boolean).with_options(default: true) }
    it { is_expected.to have_db_column(:password_changed_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:email]).unique }
    it { is_expected.to have_db_index([:last_name, :first_name]) }
  end

  describe "defaults" do
    it "force_password_reset should default to true" do
      u = AdminUser.new
      expect(u.force_password_reset).to be_truthy
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to allow_value("oliver@opsb.co.uk").for(:email)}
    it { is_expected.not_to allow_value("jimbo").for(:email) }

    it "should validate uniqueness of email" do
      FactoryBot.create(:moderator_user)
      is_expected.to validate_uniqueness_of(:email).case_insensitive
    end

    it "should only allow passwords with a digit, lower and upper case alpha and a special char" do
      ['Letmein1!', 'Letmein1_', '1Ab*aaaa'].each do |email|
        u = FactoryBot.build(:moderator_user, :password => email, :password_confirmation => email)
        expect(u).to be_valid
      end
    end

    it "should not allow passwords without a digit, lower and upper case alpha and a special char" do
      ['Letmein1', 'hell$0123', '^%ttttFFFFF', 'KJDL_3444'].each do |email|
        u = FactoryBot.build(:moderator_user, :password => email, :password_confirmation => email)
        expect(u).not_to be_valid
      end
    end

    it "should allow sysadmin role" do
      u = FactoryBot.build(:admin_user, :role => 'sysadmin')
      expect(u).to be_valid
    end

    it "should allow moderator role" do
      u = FactoryBot.build(:admin_user, :role => 'moderator')
      expect(u).to be_valid
    end

    it "should disallow other roles" do
      u = FactoryBot.build(:admin_user, :role => 'unheard_of')
      expect(u).not_to be_valid
    end
  end

  describe "scopes" do
    before :each do
      @user1 = FactoryBot.create(:sysadmin_user, :first_name => 'Ronald', :last_name => 'Reagan')
      @user2 = FactoryBot.create(:moderator_user, :first_name => 'Bill', :last_name => 'Clinton')
    end

    describe ".by_name" do
      it "should return admin users by name" do
        expect(AdminUser.by_name).to eq([@user2, @user1])
      end
    end

    describe ".by_role" do
      it "should return moderator users" do
        expect(AdminUser.by_role(AdminUser::MODERATOR_ROLE)).to eq([@user2])
      end
    end
  end

  describe "instance methods" do
    describe "#update_password" do
      let!(:user) do
        FactoryBot.create(
          :sysadmin_user,
          password: "Testing!23",
          password_confirmation: "Testing!23",
          password_changed_at: nil,
          force_password_reset: true
        )
      end

      let(:params) do
        {
          current_password: current_password, password: password,
          password_confirmation: password_confirmation
        }
      end

      let(:current_password) { "Testing!23" }
      let(:password) { "NewP4ssword!" }
      let(:password_confirmation) { "NewP4ssword!" }

      context "when the new password is valid" do
        it "returns true" do
          expect(user.update_password(params)).to be_truthy
        end

        it "changes the encrypted_password field" do
          expect {
            user.update_password(params)
          }.to change {
            user.reload.encrypted_password
          }
        end

        it "sets the timestamp for when the password was changed" do
          expect {
            user.update_password(params)
          }.to change {
            user.reload.password_changed_at
          }.from(nil).to(be_within(2.seconds).of(Time.current))
        end

        it "clears the force password reset flag" do
          expect {
            user.update_password(params)
          }.to change {
            user.reload.force_password_reset
          }.from(true).to(false)
        end
      end

      context "when the current password is missing" do
        let(:current_password) { "" }

        it "returns false" do
          expect(user.update_password(params)).to be_falsey
        end

        it "adds an error" do
          user.update_password(params)
          expect(user.errors[:current_password]).to include("Current password can’t be blank")
        end

        it "doesn't clear the force password reset flag" do
          user.update_password(params)
          expect(user.force_password_reset).to be true
        end

        it "doesn't set the password_changed_at timestamp" do
          user.update_password(params)
          expect(user.password_changed_at).to be_nil
        end
      end

      context "when the current password is incorrect" do
        let(:current_password) { "L3tme!n" }

        it "returns false" do
          expect(user.update_password(params)).to be_falsey
        end

        it "adds an error" do
          user.update_password(params)
          expect(user.errors[:current_password]).to include("Current password is incorrect")
        end

        it "doesn't clear the force password reset flag" do
          user.update_password(params)
          expect(user.force_password_reset).to be true
        end

        it "doesn't set the password_changed_at timestamp" do
          user.update_password(params)
          expect(user.password_changed_at).to be_nil
        end
      end

      context "when the new password is the same as the old password" do
        let(:password) { current_password }
        let(:password_confirmation) { current_password }

        it "returns false" do
          expect(user.update_password(params)).to be_falsey
        end

        it "adds an error" do
          user.update_password(params)
          expect(user.errors[:password]).to include("Password is the same as the current password")
        end

        it "doesn't clear the force password reset flag" do
          user.update_password(params)
          expect(user.force_password_reset).to be true
        end

        it "doesn't set the password_changed_at timestamp" do
          user.update_password(params)
          expect(user.password_changed_at).to be_nil
        end
      end

      context "when the new password is invalid" do
        let(:password) { "password" }
        let(:password_confirmation) { "password" }

        it "returns false" do
          expect(user.update_password(params)).to be_falsey
        end

        it "adds an error" do
          user.update_password(params)
          expect(user.errors[:password]).to include("Password must contain at least one digit, a lower and upper case letter and a special character")
        end

        it "doesn't clear the force password reset flag" do
          user.update_password(params)
          expect(user.force_password_reset).to be true
        end

        it "doesn't set the password_changed_at timestamp" do
          user.update_password(params)
          expect(user.password_changed_at).to be_nil
        end
      end

      context "when the new password doesn't match the confirmation" do
        let(:password) { "L3tme!n1" }
        let(:password_confirmation) { "L3tme!n2" }

        it "returns false" do
          expect(user.update_password(params)).to be_falsey
        end

        it "adds an error" do
          user.update_password(params)
          expect(user.errors[:password_confirmation]).to include("Password confirmation doesn’t match password")
        end

        it "doesn't clear the force password reset flag" do
          user.update_password(params)
          expect(user.force_password_reset).to be true
        end

        it "doesn't set the password_changed_at timestamp" do
          user.update_password(params)
          expect(user.password_changed_at).to be_nil
        end
      end
    end

    describe "#destroy" do
      context "when there is no current user and there is more than one" do
        let!(:user_1) { FactoryBot.create(:sysadmin_user) }
        let!(:user_2) { FactoryBot.create(:sysadmin_user) }

        it "returns true" do
          expect(user_1.destroy(current_user: nil)).to be_truthy
        end
      end

      context "when the user is not current and there is more than one" do
        let!(:user_1) { FactoryBot.create(:sysadmin_user) }
        let!(:user_2) { FactoryBot.create(:sysadmin_user) }

        it "returns true" do
          expect(user_1.destroy(current_user: user_2)).to be_truthy
        end
      end

      context "when the current user is itself" do
        let!(:user) { FactoryBot.create(:sysadmin_user) }

        it "raises an AdminUser::CannotDeleteCurrentUser error" do
          expect {
            user.destroy(current_user: user.reload)
          }.to raise_error(AdminUser::CannotDeleteCurrentUser)
        end
      end

      context "when there is only one user left" do
        let!(:user) { FactoryBot.create(:sysadmin_user) }

        it "raises an AdminUser::MustBeAtLeastOneAdminUser error" do
          expect {
            user.destroy(current_user: nil)
          }.to raise_error(AdminUser::MustBeAtLeastOneAdminUser)
        end
      end
    end

    describe "#name" do
      it "should return a user's name" do
        user = FactoryBot.create(:moderator_user, :first_name => 'Jo', :last_name => 'Public')
        expect(user.name).to eq('Public, Jo')
      end
    end

    describe "#is_a_sysadmin?" do
      it "should return true when user is a sysadmin" do
        user = FactoryBot.create(:admin_user, :role => 'sysadmin')
        expect(user.is_a_sysadmin?).to be_truthy
      end

      it "should return false when user is a moderator user" do
        user = FactoryBot.create(:admin_user, :role => 'moderator')
        expect(user.is_a_sysadmin?).to be_falsey
      end
    end

    describe "#is_a_moderator?" do
      it "should return true when user is a moderator user" do
        user = FactoryBot.create(:admin_user, :role => 'moderator')
        expect(user.is_a_moderator?).to be_truthy
      end

      it "should return false when user is a sysadmin" do
        user = FactoryBot.create(:admin_user, :role => 'sysadmin')
        expect(user.is_a_moderator?).to be_falsey
      end
    end

    describe "#has_to_change_password?" do
      it "should be true when force_reset_password is true" do
        user = FactoryBot.create(:moderator_user, :force_password_reset => true)
        expect(user.has_to_change_password?).to be_truthy
      end

      it "should be false when force_reset_password is false" do
        user = FactoryBot.create(:moderator_user, :force_password_reset => false)
        expect(user.has_to_change_password?).to be_falsey
      end

      it "should be true when password was last changed over 9 months ago" do
        user = FactoryBot.create(:moderator_user, :force_password_reset => false, :password_changed_at => 9.months.ago - 1.minute)
        expect(user.has_to_change_password?).to be_truthy
      end

      it "should be false when password was last changed less than 9 months ago" do
        user = FactoryBot.create(:moderator_user, :force_password_reset => false, :password_changed_at => 9.months.ago + 1.minute)
        expect(user.has_to_change_password?).to be_falsey
      end
    end

    describe "#can_take_petitions_down?" do
      it "is true if the user is a sysadmin" do
        user = FactoryBot.create(:admin_user, :role => 'sysadmin')
        expect(user.can_take_petitions_down?).to be_truthy
      end

      it "is true if the user is a moderator user" do
        user = FactoryBot.create(:admin_user, :role => 'moderator')
        expect(user.can_take_petitions_down?).to be_truthy
      end
    end

    describe "#account_disabled" do
      it "should return true when user has tried to login 5 times unsuccessfully" do
        user = FactoryBot.create(:moderator_user)
        user.failed_attempts = 5
        expect(user.account_disabled).to be_truthy
      end

      it "should return true when user has tried to login 6 times unsuccessfully" do
        user = FactoryBot.create(:moderator_user)
        user.failed_attempts = 6
        expect(user.account_disabled).to be_truthy
      end

      it "should return false when user has tried to login 4 times unsuccessfully" do
        user = FactoryBot.create(:moderator_user)
        user.failed_attempts = 4
        expect(user.account_disabled).to be_falsey
      end
    end

    describe "#account_disabled=" do
      it "should set the failed login count to 5 when true" do
        u = FactoryBot.create(:moderator_user)
        u.account_disabled = true
        expect(u.failed_attempts).to eq(5)
      end

      it "should set the failed login count to 0 when false" do
        u = FactoryBot.create(:moderator_user)
        u.failed_attempts = 5
        u.account_disabled = false
        expect(u.failed_attempts).to eq(0)
      end
    end

    describe "#elapsed_time" do
      it "returns the number of seconds since the last request" do
        user = FactoryBot.build(:admin_user)
        expect(user.elapsed_time(60.seconds.ago)).to eq(60)
      end
    end

    describe "#time_remaining" do
      before do
        allow(Site).to receive(:login_timeout).and_return(300)
      end

      it "returns the number of seconds remaining until the user is logged out" do
        user = FactoryBot.build(:admin_user)
        expect(user.time_remaining(60.seconds.ago)).to eq(240)
      end
    end
  end
end
