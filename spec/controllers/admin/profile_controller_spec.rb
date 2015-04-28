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
          response.should redirect_to(admin_login_path)
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
        @user.has_to_change_password?.should be_true
        get :edit, :id => 50000 # id does not matter
        response.should be_success
      end
    end
  end

  context "logged in" do
    before :each do
      login_as(@user)
    end
    
    without_ssl do
      describe "GET 'edit'" do
        it "should redirect to ssl" do
          get :edit, :id => 50000 # id does not matter
          response.should redirect_to(edit_admin_profile_url(:protocol => 'https'))
        end
      end
    end
    
    with_ssl do
      describe "GET 'edit'" do
        it "should render successfully" do
          get :edit, :id => 50000 # id does not matter
          response.should be_success
        end
      end
    
      describe "GET 'update'" do
        before :each do
          @time = Chronic.parse('4 August 2010 13:41')
          Time.zone.stub!(:now).and_return(@time)
        end
      
        def do_put(current_password, new_password, password_confirmation)
          put :update, :id => 50000, :current_password => current_password,
              :admin_user => {:password => new_password, :password_confirmation => password_confirmation}
        end
      
        context "successful password change" do
          it "should update password" do
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            @user.reload
            @user.valid_password?('Letmeout1!').should be_true
          end
      
          it "should update password_changed_at to current time" do
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            @user.reload
            @user.password_changed_at.should == @time
          end
        
          it "should set force_password_reset to false" do
            @user.force_password_reset.should be_true
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            @user.reload
            @user.force_password_reset.should be_false
          end
      
          it "should redirect" do
            do_put('Letmein1!', 'Letmeout1!', 'Letmeout1!')
            response.should redirect_to(admin_root_path)
          end
        end
      
        context "unsuccessful password change" do
          it "should have current password incorrect" do
            do_put('Letmeout1!', 'Letmein1!', 'Letmein1!')
            @user.valid_password?('Letmeout1!').should be_false
            @user.valid_password?('Letmein1!').should be_true
            assigns[:current_user].errors[:current_password].should_not be_blank
          end

          it "should not update password_changed_at" do
            do_put('Letmeout1!', 'Letmein1!', 'Letmein1!')
            @user.reload
            @user.password_changed_at.should_not == @time
            @user.valid_password?('Letmein1!').should be_true
          end
        
          it "should have current password and new password are the same" do
            do_put('Letmein1!', 'Letmein1!', 'Letmein1!')
            assigns[:current_user].errors[:password].should_not be_blank
            @user.reload
            @user.valid_password?('Letmein1!').should be_true
          end

          it "should have new password as invalid" do
            do_put('Letmein1!', 'aB1defgh', 'aB1defgh')
            assigns[:current_user].errors[:password].should_not be_blank
            @user.reload
            @user.valid_password?('Letmein1!').should be_true
          end
        
          it "should have password as invalid when confirmation is different" do
            do_put('Letmein1!', 'aB1!efgh', 'aB1defgh')
            assigns[:current_user].errors[:password].should_not be_blank
            @user.reload
            @user.valid_password?('Letmein1!').should be_true
          end
        end
      end
    end
  end
end