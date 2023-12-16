require 'rails_helper'

RSpec.describe "admin user persistence token", type: :request, csrf: false do
  let(:user_attributes) do
    {
      first_name: "System",
      last_name: "Administrator",
      email: "admin@petition.parliament.uk",
      password: "L3tme1n!",
      password_confirmation: "L3tme1n!"
    }
  end

  let(:login_params) do
    { email: "admin@petition.parliament.uk", password: "L3tme1n!" }
  end

  before do
    FactoryBot.create(:sysadmin_user, user_attributes)
  end

  def new_browser
    open_session do |s|
      s.reset!
      s.host! "moderate.petition.parliament.uk"
      s.https!
    end
  end

  context "when a new session is created" do
    it "logs out existing sessions" do
      s1 = new_browser
      s1.post "/admin/login", params: { user: login_params }

      expect(s1.response.status).to eq(302)
      expect(s1.response.location).to eq("https://moderate.petition.parliament.uk/admin")

      s2 = new_browser
      s2.post "/admin/login", params: { user: login_params }

      expect(s2.response.status).to eq(302)
      expect(s2.response.location).to eq("https://moderate.petition.parliament.uk/admin")

      s1.get("/admin")

      expect(s1.response.status).to eq(302)
      expect(s1.response.location).to eq("https://moderate.petition.parliament.uk/admin/login")
    end
  end

  context "when a session is destroyed" do
    it "resets the persistence token" do
      s1 = new_browser
      s1.post "/admin/login", params: { user: login_params }

      expect(s1.response.status).to eq(302)
      expect(s1.response.location).to eq("https://moderate.petition.parliament.uk/admin")

      s2 = new_browser
      s2.cookies["_epets_session"] = s1.cookies["_epets_session"]

      s1.get("/admin/logout")

      expect(s1.response.status).to eq(302)
      expect(s1.response.location).to eq("https://moderate.petition.parliament.uk/admin/login")

      s2.get("/admin")

      expect(s2.response.status).to eq(302)
      expect(s2.response.location).to eq("https://moderate.petition.parliament.uk/admin/login")
    end
  end

  context "when a session is stale" do
    before do
      host! "moderate.petition.parliament.uk"
      https!
    end

    it "resets the persistence token" do
      Site.instance.update(login_timeout: 600)

      travel_to 5.minutes.ago do
        post "/admin/login", params: { user: login_params }
        expect(response).to redirect_to("/admin")
      end

      get "/admin"
      expect(response).to be_successful

      travel_to 15.minutes.from_now do
        get "/admin"
        expect(response).to redirect_to("/admin/login")
      end

      Site.instance.update(login_timeout: 1800)

      travel_to 15.minutes.from_now do
        get "/admin"
        expect(response).to redirect_to("/admin/login")
      end
    end
  end
end
