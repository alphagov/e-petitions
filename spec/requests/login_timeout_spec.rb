require 'rails_helper'

RSpec.describe "login timeout", type: :request, csrf: false do
  let(:user_attributes) do
    {
      first_name: "System",
      last_name: "Administrator",
      email: "admin@petition.parliament.uk"
    }
  end

  let(:login_params) do
    { email: "admin@petition.parliament.uk" }
  end

  let!(:user) { FactoryBot.create(:sysadmin_user, user_attributes) }

  before do
    host! "moderate.petition.parliament.uk"
    https!
  end

  it "logs out automatically after a certain time period" do
    Site.instance.update(login_timeout: 600)

    travel_to 2.minutes.ago do
      post "/admin/auth/developer/callback", params: login_params
      expect(response).to redirect_to("/admin")
    end

    get "/admin"
    expect(response).to be_successful

    travel_to 15.minutes.from_now do
      get "/admin"
      expect(response).to redirect_to("/admin/login")
    end
  end
end
