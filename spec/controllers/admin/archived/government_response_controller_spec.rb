require 'rails_helper'

RSpec.describe Admin::Archived::GovernmentResponseController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:archived_petition) }
  let!(:creator) { FactoryBot.create(:archived_signature, :validated, creator: true, petition: petition) }
  let(:government_response) { petition.government_response }

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
      shared_examples_for 'viewing government response for a petition' do
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

      shared_examples_for 'viewing government response for a petition in the wrong state' do
        it 'throws a 404' do
          expect {
            get :show, params: { petition_id: petition.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'for a published petition' do
        it_behaves_like 'viewing government response for a petition'
      end

      describe 'for a rejected petition' do
        let!(:petition) { FactoryBot.create(:archived_petition, :rejected) }

        it_behaves_like 'viewing government response for a petition'
      end

      describe 'for a hidden petition' do
        let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

        it_behaves_like 'viewing government response for a petition'
      end
    end

    describe 'PATCH /update' do
      let(:government_response_attributes) do
        {
          responded_on: Date.civil(2018, 6, 23),
          summary: 'The government agrees',
          details: 'Your petition is brilliant and we will do our utmost to make it law.'
        }
      end

      context 'when clicking the Email button' do
        def do_patch(overrides = {})
          login_as(user)

          params = {
            petition_id: petition.id,
            archived_government_response: government_response_attributes,
            save_and_email: "Email"
          }

          patch :update, params: params.merge(overrides)
        end

        describe 'using valid params to add a government response' do
          it 'redirects to the show page' do
            do_patch
            expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}"
          end

          it 'tells the moderator that their email will be sent overnight' do
            do_patch
            expect(flash[:notice]).to eq 'Email will be sent overnight'
          end

          it 'stores the supplied government response in the db' do
            do_patch
            petition.reload
            expect(government_response.responded_on).to eq government_response_attributes[:responded_on]
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

                FactoryBot.create(:archived_signature, :validated, attributes)
              end

              2.times do |i|
                attributes = {
                  name: "Sarah #{i}",
                  email: "sarah_#{i}@example.com",
                  notify_by_email: false,
                  petition: petition
                }

                FactoryBot.create(:archived_signature, :validated, attributes)
              end

              2.times do |i|
                attributes = {
                  name: "Brian #{i}",
                  email: "brian_#{i}@example.com",
                  notify_by_email: true,
                  petition: petition
                }

                FactoryBot.create(:archived_signature, :pending, attributes)
              end

              petition.reload
            end

            it "queues a job to process the emails" do
              assert_enqueued_jobs 1 do
                do_patch
              end
            end

            it "stamps the 'government_response' email sent timestamp on each signature when the job runs" do
              perform_enqueued_jobs do
                do_patch
                petition.reload
                petition_timestamp = petition.get_email_requested_at_for('government_response')
                expect(petition_timestamp).not_to be_nil
                petition.signatures.validated.subscribed.each do |signature|
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
                  [petition.creator.email],
                  ['laura_0@example.com'],
                  ['laura_1@example.com'],
                  ['laura_2@example.com']
                ])
                expect(ActionMailer::Base.deliveries[0].subject).to match(/Government responded to “#{petition.action}”/)
                expect(ActionMailer::Base.deliveries[1].subject).to match(/Government responded to “#{petition.action}”/)
                expect(ActionMailer::Base.deliveries[2].subject).to match(/Government responded to “#{petition.action}”/)
                expect(ActionMailer::Base.deliveries[3].subject).to match(/Government responded to “#{petition.action}”/)
              end
            end
          end
        end

        describe 'using no params to add a government response' do
          before do
            government_response_attributes[:responded_on] = nil
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

          it 're-renders the admin/archived/petitions/show template' do
            do_patch
            expect(response).to be_successful
            expect(response).to render_template('admin/archived/petitions/show')
          end
        end

        describe 'using invalid params to add a government response' do
          before { government_response_attributes[:summary] = 'a' * 501 }

          it 're-renders the petitions/show template' do
            do_patch
            expect(response).to be_successful
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
            expect(government_response.responded_on).to eq government_response_attributes[:responded_on]
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

        describe 'for a published petition' do
          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a rejected petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :rejected) }

          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a hidden petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

          it_behaves_like 'adding a government response to a petition'
        end
      end

      context 'when clicking the Save button' do
        def do_patch(overrides = {})
          login_as(user)

          params = {
            petition_id: petition.id,
            archived_government_response: government_response_attributes,
            save: "Save"
          }

          patch :update, params: params.merge(overrides)
        end

        describe 'using valid params to add a government response' do
          it 'redirects to the show page' do
            do_patch
            expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}"
          end

          it 'tells the moderator that their changes were saved' do
            do_patch
            expect(flash[:notice]).to eq 'Updated government response successfully'
          end

          it 'stores the supplied government response in the db' do
            do_patch
            petition.reload
            expect(government_response.responded_on).to eq government_response_attributes[:responded_on]
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

                FactoryBot.create(:archived_signature, :validated, attributes)
              end

              2.times do |i|
                attributes = {
                  name: "Sarah #{i}",
                  email: "sarah_#{i}@example.com",
                  notify_by_email: false,
                  petition: petition
                }

                FactoryBot.create(:archived_signature, :validated, attributes)
              end

              2.times do |i|
                attributes = {
                  name: "Brian #{i}",
                  email: "brian_#{i}@example.com",
                  notify_by_email: true,
                  petition: petition
                }

                FactoryBot.create(:archived_signature, :pending, attributes)
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
            government_response_attributes[:responded_on] = nil
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

          it 're-renders the admin/archived/petitions/show template' do
            do_patch
            expect(response).to be_successful
            expect(response).to render_template('admin/archived/petitions/show')
          end
        end

        describe 'using invalid params to add a government response' do
          before { government_response_attributes[:summary] = 'a' * 501 }

          it 're-renders the petitions/show template' do
            do_patch
            expect(response).to be_successful
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
            expect(government_response.responded_on).to eq government_response_attributes[:responded_on]
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

        describe 'for a published petition' do
          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a rejected petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :rejected) }

          it_behaves_like 'adding a government response to a petition'
        end

        describe 'for a hidden petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

          it_behaves_like 'adding a government response to a petition'
        end
      end

      context "when two moderators update the response for the first time simultaneously" do
        let(:government_response) do
          FactoryBot.build(:archived_government_response, responded_on: "", summary: "", details: "", petition: petition)
        end

        before do
          moderated = double(:scope)
          allow(Archived::Petition).to receive(:moderated).and_return(moderated)
          allow(moderated).to receive(:find).with(petition.id.to_s).and_return(petition)
        end

        it "doesn't raise an ActiveRecord::RecordNotUnique error" do
          expect {
            expect(petition.government_response).to be_nil

            response_attributes = {
              responded_on: Date.civil(2018, 6, 23),
              summary: "summmary 1",
              details: "details 1"
            }

            patch :update, params: { petition_id: petition.id, archived_government_response: response_attributes, save: "Save" }
            expect(petition.government_response.summary).to eq("summmary 1")

            allow(petition).to receive(:government_response).and_return(nil, petition.government_response)
            allow(petition).to receive(:build_government_response).and_return(government_response)

            response_attributes = {
              responded_on: Date.civil(2018, 6, 23),
              summary: "summmary 2",
              details: "details 2"
            }

            patch :update, params: { petition_id: petition.id, archived_government_response: response_attributes, save: "Save" }
            expect(petition.reload_government_response.summary).to eq("summmary 2")
          }.not_to raise_error
        end
      end
    end

    describe 'DELETE /destroy' do
      before do
        expect(Archived::Petition).to receive_message_chain(:moderated, :find).with(petition.to_param).and_return(petition)
      end

      context "when the petition has a government response" do
        let!(:petition) { FactoryBot.create(:archived_petition, :response) }

        before do
          expect(petition).to receive(:government_response).and_return(government_response)
        end

        context "when the government response is succcessfully deleted" do
          it "redirects to the petition page and displays a notice" do
            delete :destroy, params: { petition_id: petition.id }

            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}")
            expect(controller).to set_flash[:notice].to("Deleted government response successfully")
          end

          it "updates the email_requested_at timestamp for 'government_response'" do
            email_requested_at = 1.hour.ago
            petition.set_email_requested_at_for("government_response", to: email_requested_at)

            expect {
              delete :destroy, params: { petition_id: petition.id }
            }.to change {
              petition.get_email_requested_at_for("government_response")
            }.from(email_requested_at).to(be_within(1.second).of(Time.current))
          end

          it "updates the government_response_at timestamp to be nil" do
            expect {
              delete :destroy, params: { petition_id: petition.id }
            }.to change {
              petition.government_response_at
            }.from(be_present).to(be_nil)
          end
        end

        context "when the government response is not successfully deleted" do
          before do
            expect(government_response).to receive(:destroy).and_return(false)
            expect(government_response).to receive(:destroyed?).and_return(false)
          end

          it "redirects to the government response page and displays an alert" do
            delete :destroy, params: { petition_id: petition.id }

            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}/government-response")
            expect(controller).to set_flash[:alert].to("Unable to delete government response - please contact support")
          end
        end
      end

      context "when the petition has no government response" do
        let!(:petition) { FactoryBot.create(:archived_petition) }
        let(:new_government_response) { petition.build_government_response }

        before do
          expect(petition).to receive(:government_response).and_return(nil)
          expect(petition).to receive(:build_government_response).and_return(new_government_response)
        end

        it "redirects to the petition page and displays a notice" do
          delete :destroy, params: { petition_id: petition.id }

          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}")
          expect(controller).to set_flash[:notice].to("Deleted government response successfully")
        end
      end
    end
  end
end
