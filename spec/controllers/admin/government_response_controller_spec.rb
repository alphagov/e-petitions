require 'rails_helper'

RSpec.describe Admin::GovernmentResponseController, type: :controller, admin: true do
  let!(:petition) { FactoryGirl.create(:open_petition) }
  let(:government_response) { petition.government_response }

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
      shared_examples_for 'viewing government response for a petition' do
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

      shared_examples_for 'viewing government response for a petition in the wrong state' do
        it 'throws a 404' do
          expect {
            get :show, petition_id: petition.id
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'for an open petition' do
        it_behaves_like 'viewing government response for a petition'
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'viewing government response for a petition in the wrong state'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'viewing government response for a petition in the wrong state'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'viewing government response for a petition in the wrong state'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
        it_behaves_like 'viewing government response for a petition'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'viewing government response for a petition'
      end
    end

    describe 'PATCH /update' do
      let(:government_response_attributes) do
        {
          summary: 'The government agrees',
          details: 'Your petition is brilliant and we will do our utmost to make it law.'
        }
      end

      context 'when clicking the Email button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            government_response: government_response_attributes,
            save_and_email: "Email"
          }

          patch :update, params.merge(overrides)
        end

        describe 'using valid params to add a government response' do
          it 'redirects to the show page' do
            do_patch
            expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}"
          end

          it 'tells the moderator that their email will be sent overnight' do
            do_patch
            expect(flash[:notice]).to eq 'Email will be sent overnight'
          end

          it 'stores the supplied government response in the db' do
            do_patch
            petition.reload
            expect(government_response.summary).to eq government_response_attributes[:summary]
            expect(government_response.details).to eq government_response_attributes[:details]
          end

          it 'stamps the current time on the government_response_at timestamp in the db' do
            time = 6.days.from_now
            travel_to time do
              do_patch
              petition.reload
              expect(petition.government_response_at).to be_within(1.second).of time
            end
          end

          it "sets the 'government_response' email requested receipt timestamp" do
            time = 5.days.from_now
            travel_to time do
              do_patch
              petition.reload
              expect(petition.get_email_requested_at_for('government_response')).to be_within(1.second).of time
            end
          end

          describe "emails out debate outcomes response" do
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

            it "stamps the 'government_response' email sent receipt on each signature when the job runs" do
              perform_enqueued_jobs do
                do_patch
                petition.reload
                petition_timestamp = petition.get_email_requested_at_for('government_response')
                expect(petition_timestamp).not_to be_nil
                petition.signatures.validated.notify_by_email.each do |signature|
                  expect(signature.get_email_sent_at_for('government_response')).to eq(petition_timestamp)
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
                expect(ActionMailer::Base.deliveries[0].subject).to match(/Government responded to your petition/)
                expect(ActionMailer::Base.deliveries[1].subject).to match(/Government responded to the petition you signed/)
                expect(ActionMailer::Base.deliveries[2].subject).to match(/Government responded to the petition you signed/)
                expect(ActionMailer::Base.deliveries[3].subject).to match(/Government responded to the petition you signed/)
              end
            end
          end
        end

        describe 'using no params to add a government response' do
          before do
            government_response_attributes[:summary] = nil
            government_response_attributes[:details] = nil
          end

          it 'does not tell the moderator that their email will be sent overnight' do
            do_patch
            expect(flash[:notice]).to be_blank
          end

          it "does not set the 'government_response' email requested receipt timestamp" do
            time = 5.days.from_now
            travel_to time do
              do_patch
              petition.reload
              expect(petition.get_email_requested_at_for('government_response')).to be_nil
            end
          end

          it "does not queue a job to process the emails" do
            assert_enqueued_jobs 0 do
              do_patch
            end
          end

          it 're-renders the admin/petitions/show template' do
            do_patch
            expect(response).to be_success
            expect(response).to render_template('admin/petitions/show')
          end
        end

        describe 'using invalid params to add a government response' do
          before { government_response_attributes[:summary] = 'a' * 501 }

          it 're-renders the petitions/show template' do
            do_patch
            expect(response).to be_success
            expect(response).to render_template('petitions/show')
          end

          it 'leaves the in-memory instance with errors' do
            do_patch
            expect(assigns(:government_response).errors).not_to be_empty
          end

          it 'does not store the supplied government response in the db' do
            do_patch
            petition.reload
            expect(government_response).to be_nil
          end

          it 'does not stamp the government_response_at timestamp in the db' do
            do_patch
            petition.reload
            expect(petition.government_response_at).to be_nil
          end

          it "does not stamp the 'government_response' email requested receipt timestamp" do
            do_patch
            petition.reload
            expect(petition.get_email_requested_at_for('government_response')).to be_nil
          end

          it "doest not queue up a job to send the 'government_response' emails" do
            do_patch
            assert_enqueued_jobs 0
          end
        end

        shared_examples_for 'adding a government response to a petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          it 'stores the supplied response on the petition in the db' do
            do_patch
            petition.reload
            expect(government_response.summary).to eq government_response_attributes[:summary]
            expect(government_response.details).to eq government_response_attributes[:details]
          end
        end

        shared_examples_for 'adding a government response to a petition in the wrong state' do
          it 'throws a 404' do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it 'does not store the supplied response on the petition in the db' do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            petition.reload
            expect(government_response).to be_nil
          end
        end

        describe 'for an open petition' do
          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'adding a government response to a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'adding a government response to a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'adding a government response to a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'adding a government response to a petition'
        end
      end

      context 'when clicking the Save button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            government_response: government_response_attributes,
            save: "Save"
          }

          patch :update, params.merge(overrides)
        end

        describe 'using valid params to add a government response' do
          it 'redirects to the show page' do
            do_patch
            expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}"
          end

          it 'tells the moderator that their changes were saved' do
            do_patch
            expect(flash[:notice]).to eq 'Updated government response successfully'
          end

          it 'stores the supplied government response in the db' do
            do_patch
            petition.reload
            expect(government_response.summary).to eq government_response_attributes[:summary]
            expect(government_response.details).to eq government_response_attributes[:details]
          end

          it 'stamps the current time on the government_response_at timestamp in the db' do
            time = 6.days.from_now
            travel_to time do
              do_patch
              petition.reload
              expect(petition.government_response_at).to be_within(1.second).of time
            end
          end

          it "does not set the 'government_response' email requested receipt timestamp" do
            time = 5.days.from_now
            travel_to time do
              do_patch
              petition.reload
              expect(petition.get_email_requested_at_for('government_response')).to be_nil
            end
          end

          describe "does not email out debate outcomes response" do
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

        describe 'using no params to add a government response' do
          before do
            government_response_attributes[:summary] = nil
            government_response_attributes[:details] = nil
          end

          it 'does not tell the moderator that their changes were saved' do
            do_patch
            expect(flash[:notice]).to be_blank
          end

          it "does not set the 'government_response' email requested receipt timestamp" do
            time = 5.days.from_now
            travel_to time do
              do_patch
              petition.reload
              expect(petition.get_email_requested_at_for('government_response')).to be_nil
            end
          end

          it "does not queue a job to process the emails" do
            assert_enqueued_jobs 0 do
              do_patch
            end
          end

          it 're-renders the admin/petitions/show template' do
            do_patch
            expect(response).to be_success
            expect(response).to render_template('admin/petitions/show')
          end
        end

        describe 'using invalid params to add a government response' do
          before { government_response_attributes[:summary] = 'a' * 501 }

          it 're-renders the petitions/show template' do
            do_patch
            expect(response).to be_success
            expect(response).to render_template('petitions/show')
          end

          it 'leaves the in-memory instance with errors' do
            do_patch
            expect(assigns(:government_response).errors).not_to be_empty
          end

          it 'does not store the supplied government response in the db' do
            do_patch
            petition.reload
            expect(government_response).to be_nil
          end

          it 'does not stamp the government_response_at timestamp in the db' do
            do_patch
            petition.reload
            expect(petition.government_response_at).to be_nil
          end

          it "does not stamp the 'government_response' email requested receipt timestamp" do
            do_patch
            petition.reload
            expect(petition.get_email_requested_at_for('government_response')).to be_nil
          end

          it "doest not queue up a job to send the 'government_response' emails" do
            do_patch
            assert_enqueued_jobs 0
          end
        end

        shared_examples_for 'adding a government response to a petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          it 'stores the supplied response on the petition in the db' do
            do_patch
            petition.reload
            expect(government_response.summary).to eq government_response_attributes[:summary]
            expect(government_response.details).to eq government_response_attributes[:details]
          end
        end

        shared_examples_for 'adding a government response to a petition in the wrong state' do
          it 'throws a 404' do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it 'does not store the supplied response on the petition in the db' do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            petition.reload
            expect(government_response).to be_nil
          end
        end

        describe 'for an open petition' do
          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'adding a government response to a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'adding a government response to a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'adding a government response to a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'adding a government response to a petition'
        end
      end
    end
  end
end
