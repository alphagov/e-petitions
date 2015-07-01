require 'rails_helper'

RSpec.describe Admin::NotesController, type: :controller do

  let!(:petition) { FactoryGirl.create(:open_petition) }

  describe 'not logged in' do
    describe 'GET /show' do
      it 'redirects to the login page' do
        get :show, petition_id: petition.id
        expect(response).to redirect_to('https://petition.parliament.uk/admin/login')
      end
    end

    describe 'PATCH /update' do
      it 'redirects to the login page' do
        patch :update, petition_id: petition.id
        expect(response).to redirect_to('https://petition.parliament.uk/admin/login')
      end
    end
  end

  context 'logged in as moderator user but need to reset password' do
    let(:user) { FactoryGirl.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe 'GET /show' do
      it 'redirects to edit profile page' do
        get :show, petition_id: petition.id
        expect(response).to redirect_to("https://petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end

    describe 'PATCH /update' do
      it 'redirects to edit profile page' do
        patch :update, petition_id: petition.id
        expect(response).to redirect_to("https://petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryGirl.create(:moderator_user) }
    before { login_as(user) }

    describe 'GET /show' do
      shared_examples_for 'viewing notes for a petition' do
        it 'fetches the requested petition' do
          get :show, petition_id: petition.id
          expect(assigns(:petition)).to eq petition
        end

        it 'responds successfully and renders the petitions/show template' do
          get :show, petition_id: petition.id
          expect(response).to be_success
          expect(response).to render_template('petitions/show')
        end
      end

      describe 'for an open petition' do
        it_behaves_like 'viewing notes for a petition'
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'viewing notes for a petition'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'viewing notes for a petition'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'viewing notes for a petition'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE, rejection_code: Petition::REJECTION_CODES.first) }
        it_behaves_like 'viewing notes for a petition'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'viewing notes for a petition'
      end
    end

    describe 'PATCH /update' do
      let(:notes_attributes) do
        {
          admin_notes: 'This seems fine, just need to get legal to give it the once over before letting it through.'
        }
      end

      def do_patch(overrides = {})
        params = { petition_id: petition.id, petition: notes_attributes }
        patch :update, params.merge(overrides)
      end

      shared_examples_for 'updating notes for a petition' do
        it 'fetches the requested petition' do
          do_patch
          expect(assigns(:petition)).to eq petition
        end

        context 'with valid params' do
          it 'redirects to the petition show page' do
            do_patch
            expect(response).to redirect_to "https://petition.parliament.uk/admin/petitions/#{petition.id}"
          end

          it 'stores the supplied notes in the db' do
            do_patch
            petition.reload
            expect(petition.admin_notes).to eq notes_attributes[:admin_notes]
          end
        end

        describe 'with invalid params' do
          before do
            # NOTE this can't fail as there's no validation
            allow_any_instance_of(Petition).to receive(:valid?) do |receiver|
              receiver.errors.add(:base, 'this is all messed up')
              false
            end
          end

          it 're-renders the petitions/show template' do
            do_patch
            expect(response).to be_success
            expect(response).to render_template('petitions/show')
          end

          it 'leaves the in-memory instance with errors' do
            do_patch
            expect(assigns(:petition)).to be_present
            expect(assigns(:petition).errors).not_to be_empty
          end

          it 'does not stores the supplied notes in the db' do
            do_patch
            petition.reload
            expect(petition.admin_notes).to be_nil
          end
        end
      end

      describe 'for an open petition' do
        it_behaves_like 'updating notes for a petition'
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'updating notes for a petition'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'updating notes for a petition'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'updating notes for a petition'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE, rejection_code: Petition::REJECTION_CODES.first) }
        it_behaves_like 'updating notes for a petition'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'updating notes for a petition'
      end
    end
  end
end
