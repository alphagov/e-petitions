require 'rails_helper'

RSpec.describe Admin::CreatorsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["DELETE", "/admin/petitions/:petition_id/creator", :destroy, { petition_id: 1 }]
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
      ["DELETE", "/admin/petitions/:petition_id/creator", :destroy, { petition_id: 1 }]
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
    let(:creator) { petition.creator }

    before { login_as(sysadmin) }
    before { allow(Petition).to receive(:find).with(petition.to_param).and_return(petition) }

    shared_examples "a petition that can't have its creator anonymized" do
      before { delete :destroy, params: { petition_id: petition.id } }

      it "redirects to the petition show page" do
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
      end

      it "sets the flash alert message" do
        expect(flash[:alert]).to eq("The creator can only be anonymized if the petition is hidden or removed")
      end
    end

    shared_examples "a petition that can have its creator anonymized" do
      context "and the creator has already been anonymized" do
        before do
          creator.anonymize!(Time.current)

          expect(Petition).to receive(:find).with(petition.to_param).and_return(petition)
          expect(petition).to receive(:creator).and_return(creator)
          expect(creator).not_to receive(:anonymize!)

          delete :destroy, params: { petition_id: petition.id }
        end

        it "redirects to the petition show page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Petition creator has already been anonymized")
        end
      end

      context "and the anonymization fails" do
        let(:exception) { ActiveRecord::RecordNotSaved.new("Unable anonymize creator") }

        before do
          expect(Petition).to receive(:find).with(petition.to_param).and_return(petition)
          expect(petition).to receive(:creator).and_return(creator)
          expect(creator).to receive(:anonymize!).and_raise(exception)

          delete :destroy, params: { petition_id: petition.id }
        end

        it "redirects to the petition show page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Could not anonymize the petition creator - please contact support")
        end

        it "hasn't anonymized the creator" do
          expect(creator.reload).not_to be_anonymized
        end
      end

      context "and the anonymization succeeds" do
        before do
          expect(Petition).to receive(:find).with(petition.to_param).and_return(petition)
          expect(petition).to receive(:creator).and_return(creator)
          expect(creator).to receive(:anonymize!).and_call_original

          delete :destroy, params: { petition_id: petition.id }
        end

        it "redirects to the petition show page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Petition creator has been anonymized")
        end

        it "has anonymized the creator" do
          expect(creator.reload).to be_anonymized
        end
      end
    end

    describe "DELETE /admin/petitions/:petition_id/creator" do
      (Petition::STATES - %w[hidden removed]).each do |state|
        context "when the petition is #{state}" do
          let(:petition) { FactoryBot.create(:"#{state}_petition") }

          it_behaves_like "a petition that can't have its creator anonymized"
        end
      end

      %w[hidden removed].each do |state|
        context "when the petition has been #{state}" do
          let(:petition) { FactoryBot.create(:"#{state}_petition") }

          it_behaves_like "a petition that can have its creator anonymized"
        end
      end
    end
  end
end
