require 'rails_helper'

RSpec.describe Admin::CompletionController, type: :controller, admin: true do
  let(:petition) do
    FactoryBot.create(:referred_petition)
  end

  describe "not logged in" do
    describe "PATCH /admin/petitions/:petition_id/completion" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "PATCH /admin/petitions/:petition_id/completion" do
      it "redirects to edit profile page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "PATCH /update" do
      it "marks the petition as completed" do
        expect {
          patch :update, params: { petition_id: petition.id }
        }.to change {
          petition.reload.state
        }.from(Petition::CLOSED_STATE).to(Petition::COMPLETED_STATE)
      end
    end
  end
end
