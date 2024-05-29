require 'rails_helper'

RSpec.describe Admin::ParliamentsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/parliament", :show, {}],
      ["PATCH", "/admin/parliament", :update, {}]
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params }

        it "redirects to the login page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
        end
      end

    end
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryBot.create(:moderator_user) }
    before { login_as(moderator) }

    [
      ["GET", "/admin/parliament", :show, {}],
      ["PATCH", "/admin/parliament", :update, {}]
    ].each do |method, path, action, params|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params }

        it "redirects to the admin hub page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
        end
      end

    end
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
    before { login_as(sysadmin) }

    describe "GET /admin/parliament" do
      before { get :show }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :show template" do
        expect(response).to render_template("admin/parliaments/show")
      end
    end

    describe "PATCH /admin/parliament" do
      let(:parliament) { Parliament.last }

      let :invalid_params do
        { government: "", opening_at: "" }
      end

      let :valid_params do
        { government: "Conservative", opening_at: 2.years.ago.iso8601 }
      end

      shared_examples_for "an invalid request" do |params|
        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/parliaments/show")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Parliament could not be updated - please check the form for errors")
        end
      end

      shared_examples_for "a valid request" do |params|
        it "redirects back to the edit page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/parliament")
        end
      end

      context "when clicking the 'Save' button" do
        before { patch :update, params: { parliament: params, button: "save" } }

        context "and the params are invalid" do
          let(:params) { invalid_params }

          it_behaves_like "an invalid request"
        end

        context "and the params are valid" do
          let(:params) { valid_params }

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Parliament updated successfully")
          end
        end
      end

      context "when clicking the 'Send dissolution emails' button" do
        before { patch :update, params: { parliament: params, button: "send_emails" } }

        context "and the params are invalid" do
          let(:params) { invalid_params }

          it_behaves_like "an invalid request"
        end

        context "and the params are valid" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: 2.weeks.from_now.iso8601,
              registration_closed_at: 3.weeks.from_now.iso8601,
              election_date: 3.weeks.from_now.to_date.iso8601,
              show_dissolution_notification: true,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing"
            }
          end

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Everyone will be notified of the early closing of their petitions")
          end

          it "enqueues a job to notify creators" do
            expect(NotifyPetitionsThatParliamentIsDissolvingJob).to have_been_enqueued.on_queue(:high_priority)
          end
        end

        context "and the params are valid but parliament isn't dissolving" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: "",
              dissolution_heading: "",
              dissolution_message: "",
              dissolution_faq_url: ""
            }
          end

          it_behaves_like "an invalid request"

          it "doesn't enqueue a job to notify creators" do
            expect(enqueued_jobs).to eq([])
          end
        end
      end

      context "when clicking the 'Schedule closure' button" do
        before { patch :update, params: { parliament: params, button: "schedule_closure" } }

        context "and the params are invalid" do
          let(:params) { invalid_params }

          it_behaves_like "an invalid request"
        end

        context "and the params are valid" do
          let(:dissolution_at) { 2.weeks.from_now.beginning_of_minute }

          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: dissolution_at.iso8601,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
              show_dissolution_notification: "true",
              notification_cutoff_at: 3.months.ago.iso8601
            }
          end

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Petitions have been scheduled to close early")
          end

          it "enqueues a job to close petitions" do
            expect(ClosePetitionsEarlyJob).to have_been_enqueued.on_queue(:high_priority).with(dissolution_at.iso8601).at(dissolution_at)
          end

          it "enqueues a job to stop petitions" do
            expect(StopPetitionsEarlyJob).to have_been_enqueued.on_queue(:high_priority).with(dissolution_at.iso8601).at(dissolution_at)
          end
        end

        context "and the params are valid but parliament isn't dissolving" do
          let(:params) { valid_params }

          it_behaves_like "an invalid request"

          it "doesn't enqueue jobs to close and stop petitions" do
            expect(enqueued_jobs).to eq([])
          end
        end
      end

      context "when clicking the 'Archive petitions' button" do
        before { patch :update, params: { parliament: params, button: "archive_petitions" } }

        context "and the params are invalid" do
          let(:params) { invalid_params }

          it_behaves_like "an invalid request"
        end

        context "and the params are valid" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: 2.weeks.ago.iso8601,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
              dissolved_heading: "Parliament is dissolved",
              dissolved_message: "All petitions are now closed"
            }
          end

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Archiving of petitions was successfully started")
          end

          it "enqueues a job to archive petitions" do
            expect(ArchivePetitionsJob).to have_been_enqueued.on_queue(:high_priority)
          end

          it "sets the archiving_started_at timestamp" do
            expect(parliament.reload.archiving_started_at).not_to be_nil
          end
        end

        context "and the params are valid but parliament hasn't dissolved yet" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: 2.weeks.from_now.iso8601,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
              dissolved_heading: "Parliament is dissolved",
              dissolved_message: "All petitions are now closed"
            }
          end

          it_behaves_like "an invalid request"

          it "doesn't enqueue a job to archive petitions" do
            expect(enqueued_jobs).to eq([])
          end

          it "doesn't set the archiving_started_at timestamp" do
            expect(parliament.reload.archiving_started_at).to be_nil
          end
        end

        context "and the params are valid but parliament isn't dissolving" do
          let(:params) { valid_params }

          it_behaves_like "an invalid request"

          it "doesn't enqueue a job to archive petitions" do
            expect(enqueued_jobs).to eq([])
          end

          it "doesn't set the archiving_started_at timestamp" do
            expect(parliament.reload.archiving_started_at).to be_nil
          end
        end
      end

      context "when clicking the 'Archive parliament' button" do
        before do
          FactoryBot.create(:closed_petition, archived_at: 1.hour.ago)
          Parliament.update!(archiving_started_at: 1.day.ago)

          patch :update, params: { parliament: params, button: "archive_parliament" }
        end

        context "and the params are invalid" do
          let(:params) { invalid_params }

          it_behaves_like "an invalid request"
        end

        context "and the params are valid" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: 2.weeks.ago.iso8601,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
              dissolved_heading: "Parliament is dissolved",
              dissolved_message: "All petitions are now closed"
            }
          end

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Parliament archived successfully")
          end

          it "enqueues a job to delete petitions" do
            expect(DeletePetitionsJob).to have_been_enqueued.on_queue(:high_priority)
          end

          it "sets the archived_at timestamp" do
            expect(parliament.reload.archived_at).not_to be_nil
          end
        end

        context "and the params are valid but parliament hasn't dissolved yet" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: 2.weeks.from_now.iso8601,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
              dissolved_heading: "Parliament is dissolved",
              dissolved_message: "All petitions are now closed"
            }
          end

          it_behaves_like "an invalid request"

          it "doesn't enqueue a job to delete petitions" do
            expect(enqueued_jobs).to eq([])
          end

          it "doesn't set the archived_at timestamp" do
            expect(parliament.reload.archived_at).to be_nil
          end
        end

        context "and the params are valid but parliament isn't dissolving" do
          let(:params) { valid_params }

          it_behaves_like "an invalid request"

          it "doesn't enqueue a job to delete petitions" do
            expect(enqueued_jobs).to eq([])
          end

          it "doesn't set the archived_at timestamp" do
            expect(parliament.reload.archived_at).to be_nil
          end
        end
      end

      context "when clicking the 'Anonymize petitions' button" do
        let(:anonymized_at) { nil }

        before do
          FactoryBot.create(:archived_petition, anonymized_at: anonymized_at)

          patch :update, params: { parliament: params, button: "anonymize_petitions" }
        end

        context "and the params are invalid" do
          let(:params) { invalid_params }

          it_behaves_like "an invalid request"
        end

        context "and the params are valid" do
          let(:params) { valid_params }

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("Anonymizing of petitions was successfully started")
          end

          it "enqueues a job to archive petitions" do
            expect(Archived::AnonymizePetitionsJob).to have_been_enqueued.on_queue(:high_priority)
          end
        end

        context "and the params are valid, but the site has been reopened for less than six months" do
          let :params do
            { government: "Conservative", opening_at: 5.months.ago.iso8601 }
          end

          it_behaves_like "an invalid request"

          it "doesn't enqueue a job to anonymize petitions" do
            expect(enqueued_jobs).to eq([])
          end
        end

        context "and the params are valid, but there are no unanonymized petitions" do
          let(:params) { valid_params }
          let(:anonymized_at) { 2.weeks.ago }

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:alert]).to eq("Anonymizing of petitions could not be started - please contact support")
          end

          it "doesn't enqueue a job to anonymize petitions" do
            expect(enqueued_jobs).to eq([])
          end
        end

        context "and the params are valid, but parliament is dissolving" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: 2.weeks.from_now.iso8601,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
              dissolved_heading: "Parliament is dissolved",
              dissolved_message: "All petitions are now closed"
            }
          end

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:alert]).to eq("Anonymizing of petitions could not be started - please contact support")
          end

          it "doesn't enqueue a job to anonymize petitions" do
            expect(enqueued_jobs).to eq([])
          end
        end

        context "and the params are valid, but parliament has dissolved" do
          let :params do
            {
              government: "Conservative",
              opening_at: 2.years.ago.iso8601,
              dissolution_at: 2.weeks.ago.iso8601,
              dissolution_heading: "Parliament is dissolving",
              dissolution_message: "This means all petitions will close in 2 weeks",
              dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
              dissolved_heading: "Parliament is dissolved",
              dissolved_message: "All petitions are now closed"
            }
          end

          it_behaves_like "a valid request"

          it "sets the flash notice message" do
            expect(flash[:alert]).to eq("Anonymizing of petitions could not be started - please contact support")
          end

          it "doesn't enqueue a job to anonymize petitions" do
            expect(enqueued_jobs).to eq([])
          end
        end
      end
    end
  end
end
