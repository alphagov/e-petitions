require 'rails_helper'

RSpec.describe Admin::ProfileController, type: :controller, admin: true do
  before :each do
    @user = FactoryBot.create(:sysadmin_user, :password => 'Letmein1!',
                           :password_confirmation => 'Letmein1!', :force_password_reset => true)
  end

  describe "not logged in" do
    describe "GET 'edit'" do
      it "should redirect to the login page" do
        get 'edit', params: { id: @user.id }
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in but need to reset password" do
    before :each do
      login_as(@user)
    end

    it "should render successfully" do
      expect(@user.has_to_change_password?).to be_truthy
      get :edit, params: { id: 50000 }
      expect(response).to be_success
    end
  end

  context "logged in" do
    before :each do
      login_as(@user)
    end

    describe "GET 'edit'" do
      it "should render successfully" do
        get :edit, params: { id: 50000 }
        expect(response).to be_success
      end
    end

    describe "GET 'update'" do
      def do_patch(current_password, new_password, password_confirmation)
        admin_user_attributes = {
          current_password: current_password,
          password: new_password,
          password_confirmation: password_confirmation
        }
        patch :update, params: { id: 50000, admin_user: admin_user_attributes }
      end

      context "successful password change" do
        it "should update password" do
          do_patch('Letmein1!', 'Letmeout1!', 'Letmeout1!')
          @user.reload
          expect(@user.valid_password?('Letmeout1!')).to be_truthy
        end

        it "should update password_changed_at to current time" do
          do_patch('Letmein1!', 'Letmeout1!', 'Letmeout1!')
          @user.reload
          expect(@user.password_changed_at).to be_within(1.second).of(Time.current)
        end

        it "should set force_password_reset to false" do
          expect(@user.force_password_reset).to be_truthy
          do_patch('Letmein1!', 'Letmeout1!', 'Letmeout1!')
          @user.reload
          expect(@user.force_password_reset).to be_falsey
        end

        it "should redirect" do
          do_patch('Letmein1!', 'Letmeout1!', 'Letmeout1!')
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
        end
      end

      context "unsuccessful password change" do
        it "should have current password incorrect" do
          do_patch('Letmeout1!', 'Letmein1!', 'Letmein1!')
          expect(@user.valid_password?('Letmeout1!')).to be_falsey
          expect(@user.valid_password?('Letmein1!')).to be_truthy
          expect(assigns[:current_user].errors[:current_password]).not_to be_blank
        end

        it "should not update password_changed_at" do
          do_patch('Letmeout1!', 'Letmein1!', 'Letmein1!')
          @user.reload
          expect(@user.password_changed_at).not_to be_within(1.second).of(Time.current)
          expect(@user.valid_password?('Letmein1!')).to be_truthy
        end

        it "should have current password and new password are the same" do
          do_patch('Letmein1!', 'Letmein1!', 'Letmein1!')
          expect(assigns[:current_user].errors[:password]).not_to be_blank
          @user.reload
          expect(@user.valid_password?('Letmein1!')).to be_truthy
        end

        it "should have new password as invalid" do
          do_patch('Letmein1!', 'aB1defgh', 'aB1defgh')
          expect(assigns[:current_user].errors[:password]).not_to be_blank
          @user.reload
          expect(@user.valid_password?('Letmein1!')).to be_truthy
        end

        it "should have password as invalid when confirmation is different" do
          do_patch('Letmein1!', 'aB1!efgh', 'aB1defgh')
          expect(assigns[:current_user].errors[:password_confirmation]).not_to be_blank
          @user.reload
          expect(@user.valid_password?('Letmein1!')).to be_truthy
        end
      end
    end
  end
end
