require 'rails_helper'

describe Admin::AdminUsersController do

  describe "not logged in" do
    with_ssl do
      describe "GET 'index'" do
        it "should redirect to the login page" do
          get 'index'
          response.should redirect_to(admin_login_path)
        end
      end

      describe "GET 'new'" do
        it "should redirect to the login page" do
          get :new
          response.should redirect_to(admin_login_path)
        end
      end
    end
  end

  describe "logged in as admin user" do
    with_ssl do
      before :each do
        @user = FactoryGirl.create(:admin_user)
        login_as(@user)
      end

      describe "GET 'index'" do
        it "should be unsuccessful" do
          get :index
          response.should redirect_to(admin_login_path)
        end
      end
    end
  end

  context "logged in as sysadmin but need to reset password" do
    with_ssl do
      before :each do
        @user = FactoryGirl.create(:sysadmin_user, :force_password_reset => true)
        login_as(@user)
      end

      it "should redirect to edit profile page" do
        @user.has_to_change_password?.should be_true
        get :index
        response.should redirect_to(edit_admin_profile_path(@user))
      end
    end
  end

  describe "logged in as sysadmin user" do
    before :each do
      @user = FactoryGirl.create(:sysadmin_user, :first_name => 'Sys', :last_name => 'Admin')
      login_as(@user)
    end

    without_ssl do
      describe "GET 'index'" do
        it "should redirect to ssl" do
          get :index
          response.should redirect_to(admin_admin_users_url(:protocol => 'https'))
        end
      end
      describe "GET 'new'" do
        it "should be successful" do
          get :new
          response.should redirect_to(new_admin_admin_user_url(:protocol => 'https'))
        end
      end
    end

    with_ssl do
      describe "GET 'index'" do
        before :each do
          @user1 = FactoryGirl.create(:admin_user, :first_name => 'John', :last_name => 'Kennedy')
          @user2 = FactoryGirl.create(:admin_user, :first_name => 'Hilary', :last_name => 'Clinton')
          @user3 = FactoryGirl.create(:admin_user, :first_name => 'Ronald', :last_name => 'Reagan')
          @user4 = FactoryGirl.create(:admin_user, :first_name => 'Bill', :last_name => 'Clinton')
        end

        it "should be successful" do
          get :index
          response.should be_success
        end

        it "should display a list of users" do
          get :index
          assigns[:users].should == [@user, @user4, @user2, @user1, @user3]
        end
      end

      describe "GET 'new'" do
        it "should be successful" do
          get :new
          response.should be_success
        end

        it "should assign a new user" do
          get :new
          assigns[:user].should be_a(AdminUser)
          assigns[:user].should be_new_record
        end
      end

      describe "POST 'create'" do
        describe "with valid params" do
          def do_create(options = {})
            post :create, {:admin_user => {
                :first_name => 'John', :last_name => 'Kennedy', :role => 'admin',
                :email => 'admin@example.com', :password => 'Letmein1!', :password_confirmation => 'Letmein1!'
              }, :department_ids => {}}.merge(options)
          end

          it "should create a new user" do
            lambda do
              do_create
            end.should change(AdminUser, :count).by(1)
          end

          it "should redirect to the index" do
            do_create
            response.should redirect_to(:action => :index)
          end

          it "create a new user with associated departments" do
            department1 = FactoryGirl.create(:department)
            department2 = FactoryGirl.create(:department)
            do_create(:department_ids => { "0" => department1.id.to_s, "1" => department2.id.to_s})
            user = AdminUser.find_by_email('admin@example.com')
            user.departments.size.should == 2
            user.departments.should include(department1, department2)
          end
        end

        describe "with invalid params" do
          def do_create
            post :create, :admin_user => {
                :email => 'admin@example.com'
              }, :department_ids => {}
          end

          it "should not create a new user" do
            lambda do
              do_create
            end.should_not change(AdminUser, :count)
          end

          it "should re-render the new template" do
            do_create
            response.should render_template('new')
          end
        end
      end

      describe "GET 'edit'" do
        before :each do
          @user = FactoryGirl.create(:admin_user)
        end
        def do_get
          get :edit, :id => @user.id
        end

        it "should be successful" do
          do_get
          response.should be_success
        end

        it "should assign the user" do
          do_get
          assigns[:user].should be_a(AdminUser)
          assigns[:user].should == @user
        end
      end

      describe "PUT 'update'" do
        before :each do
          @department1 = FactoryGirl.create(:department)
          @department2 = FactoryGirl.create(:department)
          @user = FactoryGirl.create(:admin_user, :email => "admin@example.com", :departments => [@department1, @department2], :failed_login_count => 5)
        end

        describe "with valid params" do
          def do_update(options = {})
            put :update, {:id => @user.id, :admin_user => {
                :email => "another_admin@example.com", :account_disabled => '0'
            }, :department_ids => {}}.merge(options)
          end

          it "should update the user and redirect to the index" do
            do_update
            @user.reload
            @user.email.should == "another_admin@example.com"
            response.should redirect_to(:action => :index)
          end

          it "should reset the failed login count to 0" do
            do_update
            @user.reload
            @user.failed_login_count.should == 0
          end

          it "update a user with associated departments" do
            department3 = FactoryGirl.create(:department)
            do_update(:department_ids => {'0' => @department2.id.to_s, '1' => department3.id.to_s})
            @user.reload
            @user.departments.size.should == 2
            @user.departments.should include(@department2, department3)
          end
        end

        describe "with invalid params" do
          def do_update
            put :update, :id => @user.id, :admin_user => {
                :email => "bademailaddress"
              }, :department_ids => {}
          end

          it "should not update the user" do
            do_update
            @user.reload
            @user.email.should == "admin@example.com"
            response.should render_template('edit')
          end
        end
      end

      describe "DELETE 'destroy'" do
        it "successful delete" do
          @other_user = FactoryGirl.create(:admin_user, :email => 'admin@example.com')
          lambda do
            delete :destroy, :id => @other_user.id
          end.should change(AdminUser, :count).by(-1)
          response.should redirect_to(:action => :index)
        end

        it "unsuccessful delete" do
          lambda do
            delete :destroy, :id => @user.id
          end.should_not change(AdminUser, :count)
          response.should redirect_to(:action => :index)
          flash[:error].should == "You are not allowed to delete yourself!"
        end
      end
    end
  end
end
