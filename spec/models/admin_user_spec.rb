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

    it "should allow sysadmin role" do
      u = FactoryBot.build(:admin_user, role: 'sysadmin')
      expect(u).to be_valid
    end

    it "should allow moderator role" do
      u = FactoryBot.build(:admin_user, role: 'moderator')
      expect(u).to be_valid
    end

    it "should disallow other roles" do
      u = FactoryBot.build(:admin_user, role: 'unheard_of')
      expect(u).not_to be_valid
    end
  end

  describe "scopes" do
    before :each do
      @user1 = FactoryBot.create(:sysadmin_user, first_name: 'Ronald', last_name: 'Reagan')
      @user2 = FactoryBot.create(:moderator_user, first_name: 'Bill', last_name: 'Clinton')
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

  describe "class methods" do
    describe ".find_or_create_from!" do
      let(:provider) { IdentityProvider.providers.first }

      context "when a user doesn't exist" do
        let(:auth_data1) do
          OmniAuth::AuthHash.new(
            uid: "anne.admin@example.com",
            provider: "example",
            info: {
              first_name: "Anne",
              last_name: "Admin",
              groups: ["sysadmins"]
            }
          )
        end

        let(:auth_data2) do
          OmniAuth::AuthHash.new(
            uid: "Anne.Admin@example.com",
            provider: "example",
            info: {
              first_name: "Anne",
              last_name: "Admin",
              groups: ["sysadmins"]
            }
          )
        end

        let(:auth_user1) { AdminUser.find_or_create_from!(provider, auth_data1) }
        let(:auth_user2) { AdminUser.find_or_create_from!(provider, auth_data2) }

        it "creates only one new user" do
          expect {
            expect(auth_user1).to have_attributes(email: "anne.admin@example.com")
          }.to change(AdminUser, :count).by(1)

          expect {
            expect(auth_user2).to have_attributes(email: "anne.admin@example.com")
          }.not_to change(AdminUser, :count)
        end
      end

      context "when a user exists" do
        let(:auth_data) do
          OmniAuth::AuthHash.new(
            uid: "Anne.Admin@example.com",
            provider: "example",
            info: {
              first_name: "Anne",
              last_name: "Admin",
              groups: ["sysadmins"]
            }
          )
        end

        let(:auth_user) { AdminUser.find_or_create_from!(provider, auth_data) }

        before do
          FactoryBot.create(:sysadmin_user, email: "anne.admin@example.com", first_name: "Anne", last_name: "Admin")
        end

        it "doesn't create a new user" do
          expect {
            expect(auth_user).to have_attributes(email: "anne.admin@example.com")
          }.not_to change(AdminUser, :count)
        end
      end

      context "when saving a user repeatedly fails" do
        let(:auth_data) do
          OmniAuth::AuthHash.new(
            uid: "anne.admin@example.com",
            provider: "example",
            info: {
              first_name: "Anne",
              last_name: "Admin",
              groups: ["sysadmins"]
            }
          )
        end

        let(:user) { instance_spy(AdminUser) }

        before do
          allow(AdminUser).to receive(:find_or_initialize_by).with(email: "anne.admin@example.com").and_return(user)
          allow(user).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
        end

        it "retries twice and returns nil" do
          expect(AdminUser.find_or_create_from!(provider, auth_data)).to be_nil
          expect(user).to have_received(:save!).twice
        end
      end

      %w[sysadmin moderator reviewer].each do |role|
        context "when a #{role} user " do
          (%w[sysadmin moderator reviewer] - [role]).each do |new_role|
            context "has their role changes to #{new_role}" do
              let(:auth_data) do
                OmniAuth::AuthHash.new(
                  uid: user.email,
                  provider: "example",
                  info: {
                    first_name: user.first_name,
                    last_name: user.last_name,
                    groups: [new_role.pluralize]
                  }
                )
              end

              let(:user) { FactoryBot.create(:admin_user, role: role, email: "anne.admin@example.com") }
              let(:auth_user) { AdminUser.find_or_create_from!(provider, auth_data) }

              it "updates the role correctly" do
                expect {
                  expect(auth_user).to have_attributes(email: "anne.admin@example.com")
                }.to change {
                  user.reload.role
                }.from(role).to(new_role)
              end
            end
          end
        end
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

    describe "#email=" do
      it "should downcase the email address" do
        user = FactoryBot.create(:moderator_user, email: 'SURNAMEINITIAL@example.com')
        expect(user.email).to eq('surnameinitial@example.com')
      end
    end

    describe "#name" do
      it "should return a user's name" do
        user = FactoryBot.create(:moderator_user, first_name: 'Jo', last_name: 'Public')
        expect(user.name).to eq('Public, Jo')
      end
    end

    describe "#is_a_sysadmin?" do
      it "should return true when user is a sysadmin" do
        user = FactoryBot.create(:admin_user, role: 'sysadmin')
        expect(user.is_a_sysadmin?).to be_truthy
      end

      it "should return false when user is a moderator user" do
        user = FactoryBot.create(:admin_user, role: 'moderator')
        expect(user.is_a_sysadmin?).to be_falsey
      end
    end

    describe "#is_a_moderator?" do
      it "should return true when user is a moderator user" do
        user = FactoryBot.create(:admin_user, role: 'moderator')
        expect(user.is_a_moderator?).to be_truthy
      end

      it "should return false when user is a sysadmin" do
        user = FactoryBot.create(:admin_user, role: 'sysadmin')
        expect(user.is_a_moderator?).to be_falsey
      end
    end

    describe "#can_take_petitions_down?" do
      it "is true if the user is a sysadmin" do
        user = FactoryBot.create(:admin_user, role: 'sysadmin')
        expect(user.can_take_petitions_down?).to be_truthy
      end

      it "is true if the user is a moderator user" do
        user = FactoryBot.create(:admin_user, role: 'moderator')
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
