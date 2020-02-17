require 'rails_helper'

RSpec.describe Admin::Archived::PetitionDetailsController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:archived_petition) }
  let!(:creator) { FactoryBot.create(:archived_signature, :validated, creator: true, petition: petition) }

  describe 'not logged in' do
    describe 'GET #show' do
      it 'redirects to the login page' do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petition.senedd.wales/admin/login')
      end
    end

    describe 'PATCH #update' do
      it 'redirects to the login page' do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petition.senedd.wales/admin/login')
      end
    end
  end

  context 'logged in as moderator user but need to reset password' do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe 'GET #show' do
      it 'redirects to edit profile page' do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petition.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe 'PATCH #update' do
      it 'redirects to edit profile page' do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petition.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe 'logged in as moderator user' do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe 'GET #show' do
      shared_examples_for 'viewing a petition in the correct state' do
        it 'fetches the requested petition' do
          get :show, params: { petition_id: petition.id }
          expect(assigns(:petition)).to eq petition
        end

        it 'responds successfully and renders the petition_details/show template' do
          get :show, params: { petition_id: petition.id }
          expect(response).to be_successful
          expect(response).to render_template('petition_details/show')
        end
      end

      describe 'for a published petition' do
        it_behaves_like 'viewing a petition in the correct state'
      end

      describe 'for a rejected petition' do
        let!(:petition) { FactoryBot.create(:archived_petition, :rejected) }

        it_behaves_like 'viewing a petition in the correct state'
      end

      describe 'for a hidden petition' do
        let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

        it_behaves_like 'viewing a petition in the correct state'
      end
    end

    describe 'PATCH #update' do
      let(:petition) { FactoryBot.create(:archived_petition, action: 'Old action', background: 'Old background', additional_details: 'Old additional details') }

      def do_update
        patch :update, params: {
          petition_id: petition.id,
          archived_petition: petition_attributes
        }
      end

      describe 'allowed params' do
        let(:params) do
          {
            petition_id: petition.id,
            archived_petition: {
              action: 'New action',
              background: 'New background',
              additional_details: 'New additional_details'
            }
          }
        end

        it "are limited to action, background, additional_details and creator name" do
          is_expected.to permit(:action, :background, :additional_details).for(:update, params: params).on(:archived_petition)
        end
      end

      describe 'with valid params' do
        let(:petition_attributes) do
          {
              action: 'New action',
              background: 'New background',
              additional_details: 'New additional_details'
          }
        end

        shared_examples_for 'updating a petition in the correct state' do
          it 'redirects to the edit petition page' do
            do_update
            petition.reload
            expect(response).to redirect_to"https://moderate.petition.senedd.wales/admin/archived/petitions/#{petition.id}"
          end

          it 'updates the petition' do
            do_update
            petition.reload
            expect(petition).to be_present
            expect(petition.action).to eq('New action')
            expect(petition.background).to eq('New background')
            expect(petition.additional_details).to eq('New additional_details')
          end
        end

        describe 'for a published petition' do
          it_behaves_like 'updating a petition in the correct state'
        end
      end

      describe 'with invalid params' do
        let(:petition_attributes) do
          {
              action: '',
              background: '',
              additional_details: 'Blah'
          }
        end

        shared_examples_for 'updating a petition in the correct state' do
          it 'renders the petition_details/show template again' do
            do_update
            expect(response).to be_successful
            expect(response).to render_template('petition_details/show')
          end
        end

        describe 'for a published petition' do
          it_behaves_like 'updating a petition in the correct state'
        end
      end
    end
  end
end
