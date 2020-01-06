require 'rails_helper'

RSpec.describe Admin::PetitionStatisticsController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:open_petition) }

  context "when not logged in" do
    describe "PATCH /admin/petitions/:petition_id/statistics" do
      before do
        patch :update, params: { petition_id: petition.id }
      end

      it "redirects to the login page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryBot.create(:moderator_user) }
    before { login_as(moderator) }

    describe "PATCH /admin/petitions/:petition_id/statistics" do
      before do
        patch :update, params: { petition_id: petition.id }
      end

      it "redirects to the admin hub page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
      end
    end
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
    before { login_as(sysadmin) }

    describe "PATCH /admin/petitions/:petition_id/statistics" do
      before do
        patch :update, params: { petition_id: petition.id }
      end

      it "redirects to the petition page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Updating the petition statistics - please wait a few minutes and then refresh this page")
      end

      it "enqueues a UpdatePetitionStatisticsJob" do
        update_statistics_job = {
          job: UpdatePetitionStatisticsJob,
          args: [{ "_aj_globalid" => "gid://epets/Petition/#{petition.id}" }],
          queue: "low_priority"
        }

        expect(enqueued_jobs).to eq([update_statistics_job])
      end
    end
  end
end
