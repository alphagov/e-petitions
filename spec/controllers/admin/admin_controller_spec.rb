require 'rails_helper'

RSpec.describe Admin::AdminController, type: :controller do
  let(:user) { FactoryGirl.create(:moderator_user) }

  before do
    login_as(user)
  end

  describe "flash translation" do
    let(:i18n_args) { [i18n_key, i18n_options] }

    context "when using :alert in redirect_to" do
      controller do
        def index
          redirect_to "/", alert: :update_failed
        end
      end

      let(:i18n_key) { :update_failed }
      let(:i18n_options) { { scope: :"admin.flash" } }
      let(:i18n_response) { "Update failed" }

      before do
        expect(I18n).to receive(:t).with(*i18n_args).and_return(i18n_response)
      end

      it "translates the key" do
        get :index
        expect(flash[:alert]).to eq("Update failed")
      end
    end

    context "when using :notice in redirect_to" do
      controller do
        def index
          redirect_to "/", notice: :update_succeeded
        end
      end

      let(:i18n_key) { :update_succeeded }
      let(:i18n_options) { { scope: :"admin.flash" } }
      let(:i18n_response) { "Update succeeded" }

      before do
        expect(I18n).to receive(:t).with(*i18n_args).and_return(i18n_response)
      end

      it "translates the key" do
        get :index
        expect(flash[:notice]).to eq("Update succeeded")
      end
    end

    context "when using :flash in redirect_to" do
      controller do
        def index
          redirect_to "/", flash: { error: :update_failed }
        end
      end

      let(:i18n_key) { :update_failed }
      let(:i18n_options) { { scope: :"admin.flash" } }
      let(:i18n_response) { "Update failed" }

      before do
        expect(I18n).to receive(:t).with(*i18n_args).and_return(i18n_response)
      end

      it "translates the key" do
        get :index
        expect(flash[:error]).to eq("Update failed")
      end
    end

    context "when using substitution" do
      controller do
        def index
          redirect_to "/", notice: [:search_failed, query: "foo"]
        end
      end

      let(:i18n_key) { :search_failed }
      let(:i18n_options) { { scope: :"admin.flash", query: "foo" } }
      let(:i18n_response) { "No petition that matches 'foo'" }

      before do
        expect(I18n).to receive(:t).with(*i18n_args).and_return(i18n_response)
      end

      it "translates the key" do
        get :index
        expect(flash[:notice]).to eq("No petition that matches 'foo'")
      end
    end

    context "when using a string" do
      controller do
        def index
          redirect_to "/", notice: "Update succeeded"
        end
      end

      before do
        expect(I18n).not_to receive(:t)
      end

      it "translates the key" do
        get :index
        expect(flash[:notice]).to eq("Update succeeded")
      end
    end
  end

  describe "flash rendering" do
    context "when using :alert in render :action" do
      controller do
        def index
          render :index, alert: "Login failed"
        end
      end

      it "sets flash.now" do
        get :index
        expect(flash[:alert]).to eq("Login failed")
      end
    end

    context "when using :notice in render :action" do
      controller do
        def index
          render :index, notice: "Login succeeded"
        end
      end

      it "sets flash.now" do
        get :index
        expect(flash[:notice]).to eq("Login succeeded")
      end
    end

    context "when using :flash in render :action" do
      controller do
        def index
          render :index, flash: { error: "Login failed" }
        end
      end

      it "sets flash.now" do
        get :index
        expect(flash[:error]).to eq("Login failed")
      end
    end

    context "when using :alert in render options" do
      controller do
        def index
          render action: "index", alert: "Login failed"
        end
      end

      it "sets flash.now" do
        get :index
        expect(flash[:alert]).to eq("Login failed")
      end
    end

    context "when using :notice in render options" do
      controller do
        def index
          render action: "index", notice: "Login succeeded"
        end
      end

      it "sets flash.now" do
        get :index
        expect(flash[:notice]).to eq("Login succeeded")
      end
    end

    context "when using :flash in render options" do
      controller do
        def index
          render action: "index", flash: { error: "Login failed" }
        end
      end

      it "sets flash.now" do
        get :index
        expect(flash[:error]).to eq("Login failed")
      end
    end

    context "when using render with flash translation" do
      controller do
        def index
          render :index, alert: :login_failed
        end
      end

      let(:i18n_args) { [i18n_key, i18n_options] }
      let(:i18n_key) { :login_failed }
      let(:i18n_options) { { scope: :"admin.flash" } }
      let(:i18n_response) { "Login failed" }

      before do
        expect(I18n).to receive(:t).with(*i18n_args).and_return(i18n_response)
      end

      it "sets flash.now" do
        get :index
        expect(flash[:alert]).to eq("Login failed")
      end
    end

    context "when using render with flash translation and substitution" do
      controller do
        def index
          render :index, notice: [:search_failed, query: "foo"]
        end
      end

      let(:i18n_args) { [i18n_key, i18n_options] }
      let(:i18n_key) { :search_failed }
      let(:i18n_options) { { scope: :"admin.flash", query: "foo" } }
      let(:i18n_response) { "No petition that matches 'foo'" }

      before do
        expect(I18n).to receive(:t).with(*i18n_args).and_return(i18n_response)
      end

      it "sets flash.now" do
        get :index
        expect(flash[:notice]).to eq("No petition that matches 'foo'")
      end
    end
  end
end
