require 'rails_helper'

RSpec.describe "login timeout", type: :request, csrf: false do
  let(:user_attributes) do
    {
      first_name: "System",
      last_name: "Administrator",
      email: "admin@example.com"
    }
  end

  let(:login_params) do
    { email: "admin@example.com" }
  end

  before do
    sso_user = FactoryBot.create(:sysadmin_sso_user, **user_attributes)
    OmniAuth.config.mock_auth[:example] = sso_user
  end

  before do
    host! "moderate.petition.parliament.uk"
    https!
  end

  it "logs out automatically after a certain time period" do
    Site.instance.update(login_timeout: 600)

    travel_to 2.minutes.ago do
      post "/admin/login", params: { user: login_params }

      expect(response.status).to eq(307)
      expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/auth/example")

      follow_redirect!(params: request.POST)

      expect(response.status).to eq(302)
      expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/auth/example/callback")

      follow_redirect!

      expect(response.status).to eq(200)
      expect(response).to have_header("Refresh", "0; url=https://moderate.petition.parliament.uk/admin")
    end

    get "/admin"
    expect(response).to be_successful

    travel_to 15.minutes.from_now do
      get "/admin"
      expect(response).to redirect_to("/admin/login")
    end
  end
end
