require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:email).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:persistence_token).of_type(:string) }
    it { is_expected.to have_db_column(:sign_in_count).of_type(:integer).with_options(default: 0) }
    it { is_expected.to have_db_column(:current_sign_in_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:last_sign_in_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:current_sign_in_ip).of_type(:string) }
    it { is_expected.to have_db_column(:last_sign_in_ip).of_type(:string) }
    it { is_expected.to have_db_column(:role).of_type(:string).with_options(limit: 10, null: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }

    it { is_expected.not_to have_db_column(:encrypted_password).of_type(:string) }
    it { is_expected.not_to have_db_column(:password_salt).of_type(:string) }
    it { is_expected.not_to have_db_column(:failed_attempts).of_type(:integer).with_options(default: 0) }
    it { is_expected.not_to have_db_column(:force_password_reset).of_type(:boolean).with_options(default: true) }
    it { is_expected.not_to have_db_column(:password_changed_at).of_type(:datetime) }
    it { is_expected.not_to have_db_column(:locked_at).of_type(:datetime) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:email]).unique }
    it { is_expected.to have_db_index([:last_name, :first_name]) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to allow_value("oliver@opsb.co.uk").for(:email)}
    it { is_expected.not_to allow_value("jimbo").for(:email) }

    it "should validate uniqueness of email" do
      FactoryBot.create(:moderator_user)
      is_expected.to validate_uniqueness_of(:email).case_insensitive
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
