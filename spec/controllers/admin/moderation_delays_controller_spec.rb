require 'rails_helper'

RSpec.describe Admin::ModerationDelaysController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/moderation-delay/new", :new, {}],
      ["POST", "/admin/moderation-delay", :create, {}]
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


    describe "GET /admin/moderation-delay/new" do
      before { get :new }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :new template" do
        expect(response).to render_template("admin/moderation_delays/new")
      end
    end

    describe "POST /admin/moderation-delay" do
      describe "sending a preview email" do
        let!(:petition) { FactoryBot.create(:sponsored_petition, :overdue, sponsors_signed: true) }

        before do
          perform_enqueued_jobs do
            post :create, params: { moderation_delay: params, email_preview: "Email preview" }
          end
        end

        context "with invalid params" do
          let :params do
            { subject: "", body: "" }
          end

          it "returns 200 OK" do
            expect(response).to have_http_status(:ok)
          end

          it "renders the :new template" do
            expect(response).to render_template("admin/moderation_delays/new")
          end

          it "doesn't send an email" do
            expect(deliveries).to be_empty
          end

          it "doesn't set the moderation_delay attributes in the session" do
            expect(session[:moderation_delay]).to be_nil
          end
        end

        context "with valid params" do
          let :params do
            {
              subject: "Moderation of your petition is delayed",
              body: "Sorry, but moderation of your petition is delayed for reasons."
            }
          end

          let :email do
            deliveries.last
          end

          it "renders the :new template" do
            expect(response).to render_template("admin/moderation_delays/new")
          end

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("A preview email of the moderation delay has been sent to the feedback address")
          end

          it "sends an email to the feedback address" do
            expect(email).to deliver_to("petitionscommittee@parliament.uk")
          end

          it "sets the moderation_delay attributes in the session" do
            expect(session[:moderation_delay]).to eq(
              "subject" => "Moderation of your petition is delayed",
              "body"    => "Sorry, but moderation of your petition is delayed for reasons."
            )
          end
        end
      end

      describe "sending email to the creators" do
        let!(:petition_1) do
          FactoryBot.create(
            :sponsored_petition, :overdue,
            sponsors_signed: true,
            creator_attributes: {
              name: "Barry Butler",
              email: "bazbutler@gmail.com"
            }
          )
        end

        let!(:petition_2) do
          FactoryBot.create(
            :sponsored_petition, :overdue,
            sponsors_signed: true,
            creator_attributes: {
              name: "Laura Palmer",
              email: "laurapalmer@gmail.com"
            }
          )
        end

        before do
          perform_enqueued_jobs do
            post :create, params: { moderation_delay: params, email_creators: "Email creators" }
          end
        end

        context "with invalid params" do
          let :params do
            { subject: "", body: "" }
          end

          it "returns 200 OK" do
            expect(response).to have_http_status(:ok)
          end

          it "renders the :new template" do
            expect(response).to render_template("admin/moderation_delays/new")
          end

          it "doesn't send an email" do
            expect(deliveries).to be_empty
          end

          it "doesn't set the moderation_delay attributes in the session" do
            expect(session[:moderation_delay]).to be_nil
          end
        end

        context "with valid params" do
          let :params do
            {
              subject: "Moderation of your petition is delayed",
              body: "Sorry, but moderation of your petition is delayed for reasons."
            }
          end

          let :email_1 do
            deliveries.first
          end

          let :email_2 do
            deliveries.last
          end

          it "redirects to the overdue petitions page" do
            expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions?state=overdue_in_moderation")
          end

          it "sets the flash notice message" do
            expect(flash[:notice]).to eq("An email has been sent to creators that moderation has been delayed")
          end

          it "sends an email to the creators" do
            expect(email_1).to deliver_to("bazbutler@gmail.com")
            expect(email_2).to deliver_to("laurapalmer@gmail.com")
          end

          it "sets the moderation_delay attributes in the session" do
            expect(session[:moderation_delay]).to eq(
              "subject" => "Moderation of your petition is delayed",
              "body"    => "Sorry, but moderation of your petition is delayed for reasons."
            )
          end
        end
      end
    end
  end
end
