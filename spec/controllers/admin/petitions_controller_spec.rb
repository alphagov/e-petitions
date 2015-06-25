require 'rails_helper'

RSpec.describe Admin::PetitionsController, type: :controller do
  include ActiveJob::TestHelper

  before :each do
    creator_signature = FactoryGirl.create(:signature, :email => 'john@example.com')
    @petition = FactoryGirl.create(:sponsored_petition, :creator_signature => creator_signature)
  end

  describe "not logged in" do
    describe "GET 'threshold'" do
      it "redirects to the login page" do
        get :threshold
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'index'" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end

    describe "GET 'show'" do
      it "redirects to the login page" do
        get :show, :id => @petition.id
        expect(response).to redirect_to("https://petition.parliament.uk/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    before :each do
      @user = FactoryGirl.create(:moderator_user, :force_password_reset => true)
      login_as(@user)
    end

    it "redirects to edit profile page" do
      expect(@user.has_to_change_password?).to be_truthy
      get :show, :id => @petition.id
      expect(response).to redirect_to("https://petition.parliament.uk/admin/profile/#{@user.id}/edit")
    end
  end

  describe "logged in as moderator user" do
    before :each do
      @user = FactoryGirl.create(:moderator_user)
      login_as(@user)

      @p1 = FactoryGirl.create(:open_petition)
      @p1.update_attribute(:signature_count, 11)
      @p2 = FactoryGirl.create(:open_petition)
      @p2.update_attribute(:signature_count, 10)
      @p3 = FactoryGirl.create(:open_petition)
      @p3.update_attribute(:signature_count, 9)
      @p4 = FactoryGirl.create(:closed_petition)
      @p4.update_attribute(:signature_count, 20)

      allow(Site).to receive(:threshold_for_debate).and_return(10)
    end

    it "returns all petitions that have more than the threshold number of signatures in ascending count order" do
      get :threshold
      expect(assigns[:petitions]).to eq([@p2, @p1, @p4])
    end

    context "updating scheduled debate date" do
      let!(:petition) { FactoryGirl.create(:open_petition) }

      context "edit_scheduled_debate_date" do
        it "renders a view to update scheduled debate date" do
          get :edit_scheduled_debate_date, :id => petition.id
          expect(response).to render_template("edit_scheduled_debate_date")
        end

        shared_examples_for 'trying to view edit scheduled debate date view for a petition in the wrong state' do
          it 'raises a 404 error' do
            expect {
              get :edit_scheduled_debate_date, id: petition.id
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'trying to view edit scheduled debate date view for a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'trying to view edit scheduled debate date view for a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'trying to view edit scheduled debate date view for a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_column(:state, Petition::REJECTED_STATE) }
          it_behaves_like 'trying to view edit scheduled debate date view for a petition in the wrong state'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'trying to view edit scheduled debate date view for a petition in the wrong state'
        end
      end

      context "update_scheduled_debate_date" do
        it "updates scheduled debate date with valid param" do
          patch :update_scheduled_debate_date, :id => @p1.id, :petition => { :scheduled_debate_date => '06/12/2015' }
          @p1.reload
          expect(@p1.scheduled_debate_date).to eq("06/12/2015".to_date)
        end

        shared_examples_for 'trying to view update scheduled debate date for a petition in the wrong state' do
          it 'raises a 404 error' do
            expect {
              get :edit_scheduled_debate_date, id: petition.id
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'trying to view update scheduled debate date for a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'trying to view update scheduled debate date for a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'trying to view update scheduled debate date for a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_column(:state, Petition::REJECTED_STATE) }
          it_behaves_like 'trying to view update scheduled debate date for a petition in the wrong state'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'trying to view update scheduled debate date for a petition in the wrong state'
        end
      end
    end
  end

  describe "logged in as sysadmin" do
    before :each do
      @user = FactoryGirl.create(:sysadmin_user)
      login_as(@user)
    end

    context "index" do
      let(:petitions) { double.as_null_object }

      before do
        allow(Petition).to receive(:selectable).and_return(petitions)
      end

      it "shows all selectable petitions" do
        expect(Petition).to receive(:selectable).and_return(petitions)
        get :index
      end
    end

    context "show" do
      it "assigns petition successfully" do
        get :show, :id => @petition.id
        expect(assigns(:petition)).to eq(@petition)
      end
    end
  end
end
