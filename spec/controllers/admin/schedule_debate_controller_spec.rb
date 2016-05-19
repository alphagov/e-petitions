require 'rails_helper'

RSpec.describe Admin::ScheduleDebateController, type: :controller, admin: true do

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
      shared_examples_for 'viewing scheduled debate date' do
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
        it_behaves_like 'viewing scheduled debate date'
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'viewing scheduled debate date'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'viewing scheduled debate date'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'viewing scheduled debate date'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
        it_behaves_like 'viewing scheduled debate date'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
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
            petition: scheduled_debate_date_attributes,
            save_and_email: "Email"
          }

          patch :update, params.merge(overrides)
        end

        describe 'scheduling a debate date for a petition' do
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

              it "stamps the 'debate_scheduled' email sent receipt on each signature when the job runs" do
                perform_enqueued_jobs do
                  do_patch
                  petition.reload
                  petition_timestamp = petition.get_email_requested_at_for('debate_scheduled')
                  expect(petition_timestamp).not_to be_nil
                  petition.signatures.validated.notify_by_email.each do |signature|
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
              expect(assigns(:petition).errors).to be_present
            end

            it 'does not store the supplied debate scheduled date in the db' do
              do_patch
              petition.reload
              expect(petition.scheduled_debate_date).to be_nil
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

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'scheduling a debate date'
        end
      end

      context 'when clicking the Save button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            petition: scheduled_debate_date_attributes,
            save: "Save"
          }

          patch :update, params.merge(overrides)
        end

        describe 'scheduling a debate date for a petition' do
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
              expect(assigns(:petition).errors).to be_present
            end

            it 'does not store the supplied debate scheduled date in the db' do
              do_patch
              petition.reload
              expect(petition.scheduled_debate_date).to be_nil
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

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'scheduling a debate date'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'scheduling a debate date'
        end
      end
    end
  end
end
