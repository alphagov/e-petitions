require 'rails_helper'

RSpec.describe Admin::DebateOutcomesController, type: :controller, admin: true do

  let!(:petition) { FactoryGirl.create(:open_petition) }

  describe 'not logged in' do
    describe 'GET /show' do
      it 'redirects to the login page' do
        get :show, petition_id: petition.id
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin/login')
      end
    end

    describe 'PATCH /update' do
      it 'redirects to the login page' do
        patch :update, petition_id: petition.id
        expect(response).to redirect_to('https://moderate.petition.parliament.uk/admin/login')
      end
    end
  end

  context 'logged in as moderator user but need to reset password' do
    let(:user) { FactoryGirl.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe 'GET /show' do
      it 'redirects to edit profile page' do
        get :show, petition_id: petition.id
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end

    describe 'PATCH /update' do
      it 'redirects to edit profile page' do
        patch :update, petition_id: petition.id
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryGirl.create(:moderator_user) }
    before { login_as(user) }

    describe 'GET /show' do
      describe 'for an open petition' do
        it 'fetches the requested petition' do
          get :show, petition_id: petition.id
          expect(assigns(:petition)).to eq petition
        end

        context 'that does not already have a debate outcome' do
          it 'exposes an new unsaved debate_outcome for the requested petition' do
            get :show, petition_id: petition.id
            expect(assigns(:debate_outcome)).to be_present
            expect(assigns(:debate_outcome)).not_to be_persisted
            expect(assigns(:debate_outcome).petition).to eq petition
          end
        end

        context 'that already has a debate outcome' do
          let!(:debate_outcome) { FactoryGirl.create(:debate_outcome, petition: petition) }
          it 'exposes the existing debate_outcome on the requested petition' do
            get :show, petition_id: petition.id
            expect(assigns(:debate_outcome)).to be_present
            expect(assigns(:debate_outcome)).to eq debate_outcome
          end
        end

        it 'responds successfully and renders the petitions/show template' do
          get :show, petition_id: petition.id
          expect(response).to be_success
          expect(response).to render_template('petitions/show')
        end
      end

      shared_examples_for 'trying to view a debate outcome for a petition in the wrong state' do
        it 'raises a 404 error' do
          expect {
            get :show, petition_id: petition.id
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end
    end

    describe 'PATCH /update' do
      let(:debate_outcome_attributes) do
        {
          debated_on: '2014-12-01',
          overview: 'Discussion of the 2014 Christmas Adjournment - has the house considered everything it needs to before it closes for the festive period?',
          transcript_url: 'http://www.publications.parliament.uk/pa/cm201415/cmhansrd/cm141218/debtext/141218-0003.htm#14121849000001',
          video_url: 'http://parliamentlive.tv/event/index/f9eb68af-6a5c-4a94-95d3-6108aa87e9d7?in=13:57:00'
        }
      end

      context 'when clicking the Email button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            debate_outcome: debate_outcome_attributes,
            save_and_email: "Email"
          }

          patch :update, params.merge(overrides)
        end

        describe 'for an open petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          describe 'with valid params' do
            it 'redirects to the petition show page' do
              do_patch
              expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}"
            end

            it 'tells the moderator that their email will be sent overnight' do
              do_patch
              expect(flash[:notice]).to eq 'Email will be sent overnight'
            end

            it 'stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_present
              expect(petition.debate_outcome.debated_on).to eq debate_outcome_attributes[:debated_on].to_date
              expect(petition.debate_outcome.overview).to eq debate_outcome_attributes[:overview]
              expect(petition.debate_outcome.transcript_url).to eq debate_outcome_attributes[:transcript_url]
              expect(petition.debate_outcome.video_url).to eq debate_outcome_attributes[:video_url]
            end

            describe "emails out a debate outcome response" do
              before do
                3.times do |i|
                  attributes = {
                    name: "Laura #{i}",
                    email: "laura_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  s = FactoryGirl.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Sarah #{i}",
                    email: "sarah_#{i}@example.com",
                    notify_by_email: false,
                    petition: petition
                  }

                  s = FactoryGirl.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Brian #{i}",
                    email: "brian_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  FactoryGirl.create(:pending_signature, attributes)
                end
                petition.reload
              end

              it "queues a job to process the emails" do
                assert_enqueued_jobs 1 do
                  do_patch
                end
              end

              it "stamps the 'debate_outcome' email sent receipt on each signature when the job runs" do
                perform_enqueued_jobs do
                  do_patch
                  petition.reload
                  petition_timestamp = petition.get_email_requested_at_for('debate_outcome')
                  expect(petition_timestamp).not_to be_nil
                  petition.signatures.validated.notify_by_email.each do |signature|
                    expect(signature.get_email_sent_at_for('debate_outcome')).to eq(petition_timestamp)
                  end
                end
              end

              it "should email out to the validated signees who have opted in when the delayed job runs" do
                ActionMailer::Base.deliveries.clear
                perform_enqueued_jobs do
                  do_patch
                  expect(ActionMailer::Base.deliveries.length).to eq 4
                  expect(ActionMailer::Base.deliveries.map(&:to)).to eq([
                    [petition.creator_signature.email],
                    ['laura_0@example.com'],
                    ['laura_1@example.com'],
                    ['laura_2@example.com']
                  ])
                end
              end
            end
          end

          describe 'with invalid params' do
            before { debate_outcome_attributes.delete(:debated_on) }

            it 're-renders the petitions/show template' do
              do_patch
              expect(response).to be_success
              expect(response).to render_template('petitions/show')
            end

            it 'leaves the in-memory instance with errors' do
              do_patch
              expect(assigns(:petition).debate_outcome).to be_present
              expect(assigns(:petition).debate_outcome.errors).not_to be_empty
            end

            it 'does not stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_nil
            end
          end
        end

        shared_examples_for 'trying to add debate outcome details to a petition in the wrong state' do
          it 'raises a 404 error' do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it 'does not stores the supplied debate outcome details in the db' do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            petition.reload
            expect(petition.debate_outcome).to be_nil
          end
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end
      end

      context 'when clicking the Save button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            debate_outcome: debate_outcome_attributes,
            save: "Save"
          }

          patch :update, params.merge(overrides)
        end

        describe 'for an open petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          describe 'with valid params' do
            it 'redirects to the petition show page' do
              do_patch
              expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}"
            end

            it 'tells the moderator that their changes were saved' do
              do_patch
              expect(flash[:notice]).to eq 'Updated debate outcome successfully'
            end

            it 'stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_present
              expect(petition.debate_outcome.debated_on).to eq debate_outcome_attributes[:debated_on].to_date
              expect(petition.debate_outcome.overview).to eq debate_outcome_attributes[:overview]
              expect(petition.debate_outcome.transcript_url).to eq debate_outcome_attributes[:transcript_url]
              expect(petition.debate_outcome.video_url).to eq debate_outcome_attributes[:video_url]
            end

            describe "does not email out debate outcome response" do
              before do
                3.times do |i|
                  attributes = {
                    name: "Laura #{i}",
                    email: "laura_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  s = FactoryGirl.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Sarah #{i}",
                    email: "sarah_#{i}@example.com",
                    notify_by_email: false,
                    petition: petition
                  }

                  s = FactoryGirl.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Brian #{i}",
                    email: "brian_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  FactoryGirl.create(:pending_signature, attributes)
                end
                petition.reload
              end

              it "does not queue a job to process the emails" do
                assert_enqueued_jobs 0 do
                  do_patch
                end
              end
            end
          end

          describe 'with invalid params' do
            before { debate_outcome_attributes.delete(:debated_on) }

            it 're-renders the petitions/show template' do
              do_patch
              expect(response).to be_success
              expect(response).to render_template('petitions/show')
            end

            it 'leaves the in-memory instance with errors' do
              do_patch
              expect(assigns(:petition).debate_outcome).to be_present
              expect(assigns(:petition).debate_outcome.errors).not_to be_empty
            end

            it 'does not stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_nil
            end
          end
        end

        shared_examples_for 'trying to add debate outcome details to a petition in the wrong state' do
          it 'raises a 404 error' do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it 'does not stores the supplied debate outcome details in the db' do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            petition.reload
            expect(petition.debate_outcome).to be_nil
          end
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end
      end
    end
  end
end
