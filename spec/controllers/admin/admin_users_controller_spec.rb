require 'rails_helper'

RSpec.describe Admin::AdminUsersController, type: :controller, admin: true do
  context "not logged in" do
    describe "GET 'index'" do
      it "should redirect to the login page" do
        get 'index'
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'new'" do
      it "should redirect to the login page" do
        get :new
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before :each do
      login_as(user)
    end

    describe "GET 'index'" do
      it "should be unsuccessful" do
        get :index
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
      end
    end
  end

  describe "logged in as sysadmin user" do
    let(:user) { FactoryBot.create(:sysadmin_user, :first_name => 'Sys', :last_name => 'Admin') }
    before :each do
      login_as(user)
    end

    describe "GET 'index'" do
      before :each do
        @user1 = FactoryBot.create(:moderator_user, :first_name => 'John', :last_name => 'Kennedy')
        @user2 = FactoryBot.create(:moderator_user, :first_name => 'Hilary', :last_name => 'Clinton')
        @user3 = FactoryBot.create(:moderator_user, :first_name => 'Ronald', :last_name => 'Reagan')
        @user4 = FactoryBot.create(:moderator_user, :first_name => 'Bill', :last_name => 'Clinton')
      end

      it "should be successful" do
        get :index
        expect(response).to be_successful
      end

      it "should display a list of users (sorted by name)" do
        get :index
        expect(assigns[:users]).to eq([user, @user4, @user2, @user1, @user3])
      end
    end

    describe "GET 'new'" do
      it "should be successful" do
        get :new
        expect(response).to be_successful
      end

      it "should assign a new user" do
        get :new
        expect(assigns[:user]).to be_a(AdminUser)
        expect(assigns[:user]).to be_new_record
      end
    end

    describe "POST 'create'" do
      def do_create
        post :create, params: { admin_user: admin_user_attributes }
      end

      describe "with valid params" do
        let(:admin_user_attributes) do
          {
            :first_name => 'John',
            :last_name => 'Kennedy',
            :role => 'moderator',
            :email => 'admin@example.com',
            :password => 'Letmein1!',
            :password_confirmation => 'Letmein1!'
          }
        end

        it "should create a new user" do
          expect do
            do_create
          end.to change(AdminUser, :count).by(1)
        end

        it "should redirect to the index" do
          do_create
          expect(response).to redirect_to(:action => :index)
        end
      end

      describe "with invalid params" do
        let(:admin_user_attributes) do
          {
            :email => 'admin@example.com'
          }
        end

        it "should not create a new user" do
          expect {
            do_create
          }.not_to change(AdminUser, :count)
        end

        it "should re-render the new template" do
          do_create
          expect(response).to render_template('new')
        end
      end
    end

    describe "GET 'edit'" do
      let(:edit_user) { FactoryBot.create(:moderator_user) }

      def do_get
        get :edit, params: { id: edit_user.to_param }
      end

      it "should be successful" do
        do_get
        expect(response).to be_successful
      end

      it "should assign the user" do
        do_get
        expect(assigns[:user]).to be_a(AdminUser)
        expect(assigns[:user]).to eq edit_user
      end
    end

    describe "PUT 'update'" do
      let(:edit_user) { FactoryBot.create(:moderator_user, :email => "admin@example.com", :failed_attempts => 5) }

      def do_update
        patch :update, params: {
          id: edit_user.to_param,
          admin_user: admin_user_attributes
        }
      end

      describe "with valid params" do
        let(:admin_user_attributes) do
          {
            :email => "another_admin@example.com",
            :account_disabled => '0'
          }
        end

        it "should update the user and redirect to the index" do
          do_update
          edit_user.reload
          expect(edit_user.email).to eq("another_admin@example.com")
          expect(response).to redirect_to(:action => :index)
        end

        it "should reset the failed login count to 0" do
          do_update
          edit_user.reload
          expect(edit_user.failed_attempts).to eq(0)
        end
      end

      describe "with invalid params" do
        let(:admin_user_attributes) do
          {
            :email => "bademailaddress"
          }
        end

        it "should not update the user" do
          do_update
          edit_user.reload
          expect(edit_user.email).to eq("admin@example.com")
          expect(response).to render_template('edit')
        end
      end
    end

    describe "DELETE 'destroy'" do
      let(:delete_user) { FactoryBot.create(:moderator_user, :email => 'admin@example.com') }

      it "deletes the requested user" do
        delete :destroy, params: { id: delete_user.to_param }
        expect(AdminUser.exists?(delete_user.id)).to be_falsey
        expect(response).to redirect_to(:action => :index)
      end

      it "will not let you delete yourself" do
        delete :destroy, params: { id: user.to_param }
        expect(AdminUser.exists?(user.id)).to be_truthy
        expect(response).to redirect_to(:action => :index)
        expect(flash[:alert]).to eq "You are not allowed to delete yourself!"
      end

      it "will not let you delete users that have moderated petitions" do
        petition = FactoryBot.create(:open_petition, moderated_by: delete_user)

        delete :destroy, params: { id: delete_user.to_param }
        expect(AdminUser.exists?(user.id)).to be_truthy
        expect(response).to redirect_to(:action => :index)
        expect(flash[:alert]).to eq "The user has moderated petitions so you can only deactivate their account"
      end
    end
  end
end
