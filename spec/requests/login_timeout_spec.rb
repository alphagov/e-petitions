require 'rails_helper'

RSpec.describe "login timeout", type: :request, csrf: false do
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

  let!(:user) { FactoryBot.create(:sysadmin_user, user_attributes) }

  before do
    host! "moderate.petition.parliament.uk"
    https!
  end

  it "logs out automatically after a certain time period" do
    Site.instance.update(login_timeout: 600)

    travel_to 2.minutes.ago do
      post "/admin/login", params: { user: login_params }
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
