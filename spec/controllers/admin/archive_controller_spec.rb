require 'rails_helper'

RSpec.describe Admin::ArchiveController, type: :controller, admin: true do
  let(:petition) do
    FactoryBot.create(:completed_petition)
  end

  describe "not logged in" do
    describe "PATCH /admin/petitions/:petition_id/archive" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "PATCH /admin/petitions/:petition_id/archive" do
      it "redirects to edit profile page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "PATCH /admin/petitions/:petition_id/archive" do
      it "marks the petition as archived" do
        expect {
          patch :update, params: { petition_id: petition.id }
        }.to change {
          petition.reload.archived_at
        }.from(nil).to(be_within(5.seconds).of(Time.current))
      end

      it "redirects to the petition page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
      end

      it "displays a notice" do
        patch :update, params: { petition_id: petition.id }
        expect(flash[:notice]).to eq("Petition has been successfully updated")
      end

      context "when the petition is not completed" do
        let(:petition) { FactoryBot.create(:referred_petition) }

        it "doesn't mark the petition as archived" do
          expect {
            patch :update, params: { petition_id: petition.id }
          }.not_to change {
            petition.reload.archived_at
          }.from(nil)
        end

        it "redirects to the petition page" do
          patch :update, params: { petition_id: petition.id }
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
        end

        it "displays an alert" do
          patch :update, params: { petition_id: petition.id }
          expect(flash[:alert]).to eq("Petition could not be updated - please contact support")
        end
      end
    end
  end
end
