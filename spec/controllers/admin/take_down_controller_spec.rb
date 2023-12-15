require 'rails_helper'

RSpec.describe Admin::TakeDownController, type: :controller, admin: true do
  let(:petition) do
    FactoryBot.create(:open_petition,
      creator_attributes: {
        name: "Barry Butler",
        email: "bazbutler@gmail.com"
      },
      sponsor_count: 0
    )
  end

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

  context 'logged in as reviewer user' do
    let(:user) { FactoryBot.create(:reviewer_user) }
    before { login_as(user) }

    describe 'GET /show' do
      it 'redirects to the admin hub page' do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin')
        expect(controller).to set_flash[:alert].to("You must be logged in as a moderator or system administrator to view this page")
      end
    end

    describe 'PATCH /update' do
      it 'redirects to the admin hub page' do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin')
        expect(controller).to set_flash[:alert].to("You must be logged in as a moderator or system administrator to view this page")
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe 'GET /show' do
      shared_examples_for 'viewing take down UI for a petition' do
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
      let(:emails) { ActionMailer::Base.deliveries.map{ |email| email.to.first } }
      let(:take_down_attributes) do
        { rejection: { code: rejection_code, details: 'bad things' } }
      end

      let(:deliveries) { ActionMailer::Base.deliveries }
      let(:creator_email) { deliveries.detect{ |m| m.to == %w[bazbutler@gmail.com] } }
      let(:sponsor_email) { deliveries.detect{ |m| m.to == %w[laurapalmer@gmail.com] } }
      let(:pending_email) { deliveries.detect{ |m| m.to == %w[sandyfisher@hotmail.com] } }
      let!(:sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition, email: "laurapalmer@gmail.com") }
      let!(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition, email: "sandyfisher@hotmail.com") }

      def do_patch(overrides = {})
        params = { petition_id: petition.id, petition: take_down_attributes, save_and_email: "Email petition creator" }
        patch :update, params: params.merge(overrides)
      end

      context 'using valid take down params' do
        shared_examples_for 'rejecting a petition' do
          before do
            perform_enqueued_jobs do
              do_patch
              petition.reload
            end
          end

          it 'sets the petition state to "rejected"' do
            expect(petition.state).to eq(Petition::REJECTED_STATE)
          end

          it 'sets the rejection code and description to the supplied params' do
            expect(petition.rejection.code).to eq(rejection_code)
            expect(petition.rejection.details).to eq("bad things")
          end

          it 'redirects to the admin show page for the petition' do
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
          end

          it "sends an email to the petition creator" do
            expect(creator_email).to deliver_to("bazbutler@gmail.com")
            expect(creator_email.subject).to match(/We rejected your petition “[^"]+”/)
          end

          it "sends an email to validated petition sponsors" do
            expect(sponsor_email).to deliver_to("laurapalmer@gmail.com")
            expect(sponsor_email.subject).to match(/We rejected the petition “[^"]+” that you supported/)
          end

          it "does not send an email to pending petition sponsors" do
            expect(pending_email).to be_nil
          end
        end

        context 'with rejection code of "duplicate"' do
          let(:rejection_code) { 'duplicate' }

          it_behaves_like 'rejecting a petition'
        end

        shared_examples_for 'hiding a petition' do
          before do
            perform_enqueued_jobs do
              do_patch
              petition.reload
            end
          end

          it 'sets the petition state to "hidden"' do
            expect(petition.state).to eq(Petition::HIDDEN_STATE)
          end

          it 'sets the rejection code to the supplied code' do
            expect(petition.rejection.code).to eq(rejection_code)
          end

          it 'redirects to the admin show page for the petition' do
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
          end

          it "sends an email to the petition creator" do
            expect(creator_email).to deliver_to("bazbutler@gmail.com")
            expect(creator_email.subject).to match(/We rejected your petition “[^"]+”/)
          end

          it "sends an email to validated petition sponsors" do
            expect(sponsor_email).to deliver_to("laurapalmer@gmail.com")
            expect(sponsor_email.subject).to match(/We rejected the petition “[^"]+” that you supported/)
          end

          it "does not send an email to pending petition sponsors" do
            expect(pending_email).to be_nil
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

          before do
            perform_enqueued_jobs do
              do_patch
              petition.reload
            end
          end

          it "leaves the state alone in the DB, and in-memory" do
            expect(petition.state).to eq(Petition::OPEN_STATE)
            expect(assigns(:petition).state).to eq(Petition::OPEN_STATE)
          end

          it "renders the petitions/show template" do
            expect(response).to be_successful
            expect(response).to render_template 'petitions/show'
          end

          it "displays an alert" do
            expect(response).to be_successful
            expect(flash[:alert]).to eq("Petition could not be taken down - please check the form for errors")
          end
        end
      end

      shared_examples_for 'taking down a petition' do
        before do
          perform_enqueued_jobs do
            do_patch
            petition.reload
          end
        end

        it 'fetches the requested petition' do
          expect(assigns(:petition)).to eq petition
        end

        it 'performs the requested take down on the petition' do
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
