require 'rails_helper'

RSpec.describe Admin::Archived::ScheduleDebateController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:archived_petition) }
  let!(:creator) { FactoryBot.create(:archived_signature, :validated, creator: true, petition: petition) }

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
      shared_examples_for 'viewing scheduled debate date' do
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
        it_behaves_like 'viewing scheduled debate date'
      end

      describe 'for a rejected petition' do
        let!(:petition) { FactoryBot.create(:archived_petition, :rejected) }

        it_behaves_like 'viewing scheduled debate date'
      end

      describe 'for a hidden petition' do
        let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

        it_behaves_like 'viewing scheduled debate date'
      end
    end

    describe 'PATCH /update' do
      let(:scheduled_debate_date_attributes) do
        {
          scheduled_debate_date: '2014-12-01',
        }
      end

      context 'when clicking the Email button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            archived_petition: scheduled_debate_date_attributes,
            save_and_email: "Email"
          }

          patch :update, params: params.merge(overrides)
        end

        describe 'scheduling a debate date for a petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          describe 'with valid params' do
            it 'redirects to the petition show page' do
              do_patch
              expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}"
            end

            it 'tells the moderator that their email will be sent overnight' do
              do_patch
              expect(flash[:notice]).to eq 'Email will be sent overnight'
            end

            it 'stores the supplied scheduled debate date against the petition in the db' do
              do_patch
              petition.reload
              expect(petition.scheduled_debate_date).to eq Date.parse('2014-12-01')
            end

            describe "emails out debate scheduled response" do
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

              it "stamps the 'debate_scheduled' email sent timestamp on each signature when the job runs" do
                perform_enqueued_jobs do
                  do_patch
                  petition.reload
                  petition_timestamp = petition.get_email_requested_at_for('debate_scheduled')
                  expect(petition_timestamp).not_to be_nil
                  petition.signatures.validated.subscribed.each do |signature|
                    expect(signature.get_email_sent_at_for('debate_scheduled')).to eq(petition_timestamp)
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
                end
              end
            end
          end

          describe "with an invalid date" do
            let(:scheduled_debate_date_attributes) do
              { scheduled_debate_date: '9999-99-99' }
            end

            before do
              do_patch
            end

            it "returns 200 OK" do
              expect(response).to have_http_status(:ok)
            end

            it "renders the :show template" do
              expect(response).to render_template("admin/archived/petitions/show")
            end

            it "displays an alert" do
              expect(flash[:alert]).to eq("Petition could not be updated - please check the form for errors")
            end
          end
        end

        shared_examples_for 'scheduling a debate date' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          it 'stores the supplied schedule date on the petition' do
            do_patch
            petition.reload
            expect(petition.scheduled_debate_date).to eq Date.parse('2014-12-01')
          end
        end

        describe 'for an open petition' do
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a rejected petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :rejected) }

          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a hidden petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

          it_behaves_like 'scheduling a debate date'
        end
      end

      context 'when clicking the Save button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            archived_petition: scheduled_debate_date_attributes,
            save: "Save"
          }

          patch :update, params: params.merge(overrides)
        end

        describe 'scheduling a debate date for a petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          describe 'with valid params' do
            it 'redirects to the petition show page' do
              do_patch
              expect(response).to redirect_to "https://moderate.petition.parliament.uk/admin/archived/petitions/#{petition.id}"
            end

            it 'tells the moderator that their changes were saved' do
              do_patch
              expect(flash[:notice]).to eq 'Updated the scheduled debate date successfully'
            end

            it 'stores the supplied scheduled debate date against the petition in the db' do
              do_patch
              petition.reload
              expect(petition.scheduled_debate_date).to eq Date.parse('2014-12-01')
            end

            describe "does not email out debate scheduled response" do
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

          describe "with an invalid date" do
            let(:scheduled_debate_date_attributes) do
              { scheduled_debate_date: '9999-99-99' }
            end

            before do
              do_patch
            end

            it "returns 200 OK" do
              expect(response).to have_http_status(:ok)
            end

            it "renders the :show template" do
              expect(response).to render_template("admin/archived/petitions/show")
            end

            it "displays an alert" do
              expect(flash[:alert]).to eq("Petition could not be updated - please check the form for errors")
            end
          end
        end

        shared_examples_for 'scheduling a debate date' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          it 'stores the supplied schedule date on the petition' do
            do_patch
            petition.reload
            expect(petition.scheduled_debate_date).to eq Date.parse('2014-12-01')
          end
        end

        describe 'for an open petition' do
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a rejected petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :rejected) }

          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a hidden petition' do
          let!(:petition) { FactoryBot.create(:archived_petition, :hidden) }

          it_behaves_like 'scheduling a debate date'
        end
      end
    end
  end
end
