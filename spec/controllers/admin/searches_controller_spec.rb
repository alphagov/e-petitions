require 'rails_helper'

describe Admin::SearchesController do

  describe "not logged in" do
    with_ssl do
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

      describe "GET 'new'" do
        it "is successful" do
          get :new
          response.should be_success
        end
        it "sets @query to blank" do
          get :new
          assigns(:query).should == ""
        end
      end

      describe "GET 'result'" do
        context "searching for email address" do
          let(:signatures) { double }
          it "returns an array of signatures for an email address" do
            signatures.stub(:paginate => signatures)
            Signature.stub(:for_email => signatures)
            get :result, :search => { :query => 'something@example.com' }
            assigns(:signatures).should == signatures
          end

          it "sets @query" do
            get :result, :search => { :query => 'foo bar' }
            assigns(:query).should == "foo bar"
          end
        end

        context "searching for e-petition by id" do
          let(:petition) { double(:to_param => '123', :editable_by? => false, :response_editable_by? => false) }
          before do
            Petition.stub(:find => petition)
          end

          it "redirects to a petition if the id exists" do
            get :result, :search => { :query => '123' }
            response.should redirect_to(admin_petition_path(petition))
          end

          context "where the petition is editable by us" do
            let(:options) { { :editable_by? => true } }
            it "redirects to the edit page" do
              petition.stub(options.merge(:awaiting_moderation? => true))
              get :result, :search => { :query => '123' }
              response.should redirect_to(edit_admin_petition_path(petition))
            end

            context "and is open" do
              before do
                options.merge!(:awaiting_moderation? => false)
              end

              it "redirects to the internal response page if we can't edit responses" do
                petition.stub(options)
                get :result, :search => { :query => '123' }
                response.should redirect_to(edit_internal_response_admin_petition_path(petition))
              end

              it "redirects to the edit response page if we can edit responses" do
                petition.stub(options.merge(:response_editable_by? => true))
                get :result, :search => { :query => '123' }
                response.should redirect_to(edit_response_admin_petition_path(petition))
              end
            end
          end

          context "when petition not found" do
            before do
              Petition.stub(:find).and_raise(ActiveRecord::RecordNotFound)
            end

            it "renders the form with an error" do
              get :result, :search => { :query => '123' }
              response.should redirect_to(new_admin_search_path)
            end

            it "sets the flash error" do
              get :result, :search => { :query => '123' }
              flash[:error].should match(/123/)
            end
          end
        end
      end
    end
  end
end
