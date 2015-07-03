require 'rails_helper'

RSpec.describe Admin::TakeDownController, type: :controller, admin: true do

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
      shared_examples_for 'viewing take down UI for a petition' do
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
        it_behaves_like 'viewing take down UI for a petition'
      end

      describe 'for a closed petition' do
        before { petition.update_column(:closed_at, 2.days.ago) }
        it_behaves_like 'viewing take down UI for a petition'
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'viewing take down UI for a petition'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'viewing take down UI for a petition'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'viewing take down UI for a petition'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
        it_behaves_like 'viewing take down UI for a petition'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'viewing take down UI for a petition'
      end
    end

    describe 'PATCH /update' do
      let(:rejection_code) { 'duplicate' }
      let(:email) { ActionMailer::Base.deliveries.last }
      let(:take_down_attributes) do
        { rejection: { code: rejection_code, details: 'bad things' } }
      end

      def do_patch(overrides = {})
        params = { petition_id: petition.id, petition: take_down_attributes }
        patch :update, params.merge(overrides)
      end

      context 'using valid take down params' do
        shared_examples_for 'rejecting a petition' do
          it 'sets the petition state to "rejected"' do
            do_patch
            petition.reload
            expect(petition.state).to eq(Petition::REJECTED_STATE)
          end

          it 'sets the rejection code and description to the supplied params' do
            do_patch
            petition.reload
            expect(petition.rejection.code).to eq(rejection_code)
            expect(petition.rejection.details).to eq("bad things")
          end

          it 'redirects to the admin show page for the petition' do
            do_patch
            expect(response).to redirect_to("https://petition.parliament.uk/admin/petitions/#{petition.id}")
          end

          it "sends an email to the petition creator" do
            do_patch
            expect(email.from).to eq(["no-reply@test.epetitions.website"])
            expect(email.to).to eq([petition.creator_signature.email])
            expect(email.subject).to match(/We rejected your petition/)
          end

          it "sends an email to validated petition sponsors" do
            validated_sponsor_1  = FactoryGirl.create(:sponsor, :validated, petition: petition)
            validated_sponsor_2  = FactoryGirl.create(:sponsor, :validated, petition: petition)
            do_patch
            expect(email.bcc).to match_array([validated_sponsor_1.signature.email, validated_sponsor_2.signature.email])
          end

          it "does not send an email to pending petition sponsors" do
            pending_sponsor = FactoryGirl.create(:sponsor, :pending, petition: petition)
            do_patch
            expect(email.bcc).not_to include([pending_sponsor.signature.email])
          end
        end

        context 'with rejection code of "duplicate"' do
          let(:rejection_code) { 'duplicate' }

          it_behaves_like 'rejecting a petition'
        end

        shared_examples_for 'hiding a petition' do
          it 'sets the petition state to "hidden"' do
            do_patch
            petition.reload
            expect(petition.state).to eq(Petition::HIDDEN_STATE)
          end

          it 'sets the rejection code to the supplied code' do
            do_patch
            petition.reload
            expect(petition.rejection.code).to eq(rejection_code)
          end

          it 'redirects to the admin show page for the petition' do
            do_patch
            expect(response).to redirect_to("https://petition.parliament.uk/admin/petitions/#{petition.id}")
          end

          it "sends an email to the petition creator" do
            do_patch
            expect(email.from).to eq(["no-reply@test.epetitions.website"])
            expect(email.to).to eq([petition.creator_signature.email])
            expect(email.subject).to match(/We rejected your petition/)
          end

          it "sends an email to validated petition sponsors" do
            validated_sponsor_1  = FactoryGirl.create(:sponsor, :validated, petition: petition)
            validated_sponsor_2  = FactoryGirl.create(:sponsor, :validated, petition: petition)
            do_patch
            expect(email.bcc).to match_array([validated_sponsor_1.signature.email, validated_sponsor_2.signature.email])
          end

          it "does not send an email to pending petition sponsors" do
            pending_sponsor = FactoryGirl.create(:sponsor, :pending, petition: petition)
            do_patch
            expect(email.bcc).not_to include([pending_sponsor.signature.email])
          end
        end

        context 'with rejection code of "offensive"' do
          let(:rejection_code) { 'offensive' }

          it_behaves_like 'hiding a petition'
        end

        context 'with rejection code of "libellous"' do
          let(:rejection_code) { 'libellous' }

          it_behaves_like 'hiding a petition'
        end

        context 'with no rejection code' do
          let(:rejection_code) { '' }

          it "leaves the state alone in the DB, and in-memory" do
            do_patch
            petition.reload
            expect(petition.state).to eq(Petition::OPEN_STATE)
            expect(assigns(:petition).state).to eq(Petition::OPEN_STATE)
          end

          it "renders the petitions/show template" do
            do_patch
            expect(response).to be_success
            expect(response).to render_template 'petitions/show'
          end
        end
      end

      shared_examples_for 'taking down a petition' do
        it 'fetches the requested petition' do
          do_patch
          expect(assigns(:petition)).to eq petition
        end

        it 'performs the requested take down on the petition' do
          do_patch
          petition.reload
          expect(petition.state).to eq Petition::REJECTED_STATE
          expect(petition.rejection.code).to eq(take_down_attributes[:rejection][:code])
          expect(petition.rejection.details).to eq(take_down_attributes[:rejection][:details])
        end
      end

      describe 'for an open petition' do
        it_behaves_like 'taking down a petition'
      end

      describe 'for a closed petition' do
        before { petition.update_column(:closed_at, 3.days.ago) }
        it_behaves_like 'taking down a petition'
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'taking down a petition'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'taking down a petition'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'taking down a petition'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
        it_behaves_like 'taking down a petition'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'taking down a petition'
      end
    end
  end
end
