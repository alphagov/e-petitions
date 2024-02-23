require 'rails_helper'

RSpec.describe Admin::NotesController, type: :controller, admin: true do

  let!(:petition) { FactoryBot.create(:open_petition) }

  context 'not logged in' do
    describe 'GET /show' do
      it 'redirects to the login page' do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin/login')
      end
    end

    describe 'PATCH /update' do
      it 'redirects to the login page' do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin/login')
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe 'GET /show' do
      shared_examples_for 'viewing notes for a petition' do
        it 'fetches the requested petition' do
          get :show, params: { petition_id: petition.id }
          expect(assigns(:petition)).to eq petition
        end

        it 'responds successfully and renders the petitions/show template' do
          get :show, params: { petition_id: petition.id }
          expect(response).to be_successful
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
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
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
          details: 'This seems fine, just need to get legal to give it the once over before letting it through.'
        }
      end

      def do_patch(overrides = {})
        params = { petition_id: petition.id, note: notes_attributes }
        patch :update, params: params.merge(overrides)
      end

      shared_examples_for 'updating notes for a petition' do
        it 'fetches the requested petition' do
          do_patch
          expect(assigns(:petition)).to eq petition
        end

        context 'with valid params' do
          it 'redirects to the petition show page' do
            do_patch
            expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}"
          end

          it 'stores the supplied notes in the db' do
            do_patch
            petition.reload
            expect(petition.note.details).to eq notes_attributes[:details]
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
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
        it_behaves_like 'updating notes for a petition'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'updating notes for a petition'
      end

      context "when two moderators update the notes for the first time simultaneously" do
        let(:note) { FactoryBot.build(:note, details: "", petition: petition) }

        before do
          allow(Petition).to receive(:find).with(petition.id.to_s).and_return(petition)
        end

        it "doesn't raise an ActiveRecord::RecordNotUnique error" do
          expect {
            expect(petition.note).to be_nil

            patch :update, params: { petition_id: petition.id, note: { details: "update 1" } }
            expect(petition.note.details).to eq("update 1")

            allow(petition).to receive(:note).and_return(nil, petition.note)
            allow(petition).to receive(:build_note).and_return(note)

            patch :update, params: { petition_id: petition.id, note: { details: "update 2" } }
            expect(petition.reload_note.details).to eq("update 2")
          }.not_to raise_error
        end
      end

      context "when updating the notes fails for an unknown reason" do
        let(:note) { FactoryBot.build(:note, details: "", petition: petition) }

        before do
          expect(Petition).to receive(:find).with(petition.to_param).and_return(petition)
          expect(petition).to receive(:note).and_return(note)
          expect(note).to receive(:update).and_return(false)

          patch :update, params: { petition_id: petition.to_param, note: { details: "" } }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/petitions/show")
        end

        it "displays an alert" do
          expect(flash[:alert]).to eq("Petition could not be updated - please contact support")
        end
      end
    end
  end
end
