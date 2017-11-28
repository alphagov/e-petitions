require 'rails_helper'

RSpec.describe Admin::TasksController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["POST", "/admin/tasks", :create, {}]
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
      ["POST", "/admin/tasks", :create, {}]
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

    describe "POST /admin/tasks" do
      context "with no selected tasks" do
        before do
          expect(Admin::TaskRunner).not_to receive(:run)
          post :create, params: { tasks: [] }
        end

        it "redirects back to the tasks tab" do
          expect(response).to redirect_to("/admin/site/edit?tab=tasks")
        end

        it "sets the flash :notice key" do
          expect(flash[:notice]).to eq("Please select one or more tasks to execute")
        end
      end

      context "with invalid params" do
        before do
          expect(Admin::TaskRunner).to receive(:run).and_return(false)
          post :create, params: { tasks: %w[task_1], task_1: {} }
        end

        it "redirects back to the tasks tab" do
          expect(response).to redirect_to("/admin/site/edit?tab=tasks")
        end

        it "sets the flash :notice key" do
          expect(flash[:notice]).to eq("There was a problem starting the tasks - please contact support")
        end
      end

      context "with one task" do
        before do
          expect(Admin::TaskRunner).to receive(:run).and_return(true)
          post :create, params: { tasks: %w[task_1], task_1: {} }
        end

        it "redirects back to the tasks tab" do
          expect(response).to redirect_to("/admin/site/edit?tab=tasks")
        end

        it "sets the flash :notice key" do
          expect(flash[:notice]).to eq("Task started successfully")
        end
      end

      context "with two tasks" do
        before do
          expect(Admin::TaskRunner).to receive(:run).and_return(true)
          post :create, params: { tasks: %w[task_1 task_2], task_1: {}, task_2: {} }
        end

        it "redirects back to the tasks tab" do
          expect(response).to redirect_to("/admin/site/edit?tab=tasks")
        end

        it "sets the flash :notice key" do
          expect(flash[:notice]).to eq("Tasks started successfully")
        end
      end
    end
  end
end
