require 'rails_helper'

describe Admin::ProfileController do
  before :each do
    @user = FactoryGirl.create(:sysadmin_user, :password => 'Letmein1!',
                           :password_confirmation => 'Letmein1!', :force_password_reset => true)
  end

  describe "not logged in" do
    with_ssl do
      describe "GET 'edit'" do
        it "should redirect to the login page" do
          get 'edit', :id => @user.id
          expect(response).to redirect_to(admin_login_path)
        end
      end
    end
  end

  context "logged in but need to reset password" do
    before :each do
      login_as(@user)
    end

    with_ssl do
      it "should render successfully" do
        expect(@user.has_to_change_password?).to be_truthy
        get :edit, :id => 50000 # id does not matter
        expect(response).to be_success
      end
    end
  end

  context "logged in" do
    before :each do
      login_as(@user)
    end

    with_ssl do
      describe "GET 'edit'" do
        it "should render successfully" do
          get :edit, :id => 50000 # id does not matter
          expect(response).to be_success
        end
      end

      describe "GET 'update'" do
        before :each do
          @time = Chronic.parse('4 August 2010 13:41')
          allow(Time.zone).to receive(:now).and_return(@time)
        end

        def do_put(current_password, new_password, password_confirmation)
          put :update, :id => 50000, :current_password => current_password,
              :admin_user => {:password => new_password, :password_confirmation => password_confirmation}
        end

        context "successful password change" do
          it "should update password" do
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            @user.reload
            expect(@user.valid_password?('Letmeout1!')).to be_truthy
          end

          it "should update password_changed_at to current time" do
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            @user.reload
            expect(@user.password_changed_at).to eq(@time)
          end

          it "should set force_password_reset to false" do
            expect(@user.force_password_reset).to be_truthy
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            @user.reload
            expect(@user.force_password_reset).to be_falsey
          end

          it "should redirect" do
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            expect(response).to redirect_to(admin_root_path)
          end
        end

        context "unsuccessful password change" do
          it "should have current password incorrect" do
            do_put('Letmeout1!', 'Letmein1!', 'Letmein1!')
            expect(@user.valid_password?('Letmeout1!')).to be_falsey
            expect(@user.valid_password?('Letmein1!')).to be_truthy
            expect(assigns[:current_user].errors[:current_password]).not_to be_blank
          end

          it "should not update password_changed_at" do
            do_put('Letmeout1!', 'Letmein1!', 'Letmein1!')
            @user.reload
            expect(@user.password_changed_at).not_to eq(@time)
            expect(@user.valid_password?('Letmein1!')).to be_truthy
          end

          it "should have current password and new password are the same" do
            do_put('Letmein1!', 'Letmein1!', 'Letmein1!')
            expect(assigns[:current_user].errors[:password]).not_to be_blank
            @user.reload
            expect(@user.valid_password?('Letmein1!')).to be_truthy
          end

          it "should have new password as invalid" do
            do_put('Letmein1!', 'aB1defgh', 'aB1defgh')
            expect(assigns[:current_user].errors[:password]).not_to be_blank
            @user.reload
            expect(@user.valid_password?('Letmein1!')).to be_truthy
          end

          it "should have password as invalid when confirmation is different" do
            do_put('Letmein1!', 'aB1!efgh', 'aB1defgh')
            expect(assigns[:current_user].errors[:password]).not_to be_blank
            @user.reload
            expect(@user.valid_password?('Letmein1!')).to be_truthy
          end
        end
      end
    end
  end
end
