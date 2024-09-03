require 'rails_helper'

RSpec.describe 'Requests containing invalid characters are rejected', type: :request, show_exceptions: true do
  it 'returns 400 for a parameter containing a null byte' do
    get "/petitions", params: { q: "bad\u0000request" }
    expect(response.status).to eq 400
  end

  it 'returns 400 for a parameter containing a null byte in an array' do
    get "/petitions", params: { q: ["bad\u0000request"] }
    expect(response.status).to eq 400
  end

  it 'returns 400 for a parameter containing a null byte in a hash' do
    get "/petitions", params: { q: { key: "bad\u0000request" } }
    expect(response.status).to eq 400
  end

  it 'returns 400 for a malformed multipart/form-data request' do
    post "/petitions", params: "--12345", headers: { 'Content-Type' => 'multipart/form-data; boundary=12345' }
    expect(response.status).to eq 400
  end

  context "when logged in as an admin", csrf: false do
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
      host! "moderate.petition.parliament.uk"
      https!

      sso_user = FactoryBot.create(:sysadmin_sso_user, **user_attributes)
      OmniAuth.config.mock_auth[:example] = sso_user

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

    context "and uploading a debate outcome image" do
      let!(:petition) { FactoryBot.create(:debated_petition) }
      let!(:image) { fixture_file_upload('debate_outcome/blank_image-2x.jpg') }

      it 'does not return 400 for an image containing null bytes' do
        patch "/admin/petitions/#{petition.id}/debate-outcome", params: { debate_outcome: { image: image } }

        expect(response.status).to eq(302)
        expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/petitions/#{petition.id}")
      end
    end
  end

  context "when attempting to login as an admin", csrf: false do
    before do
      host! "moderate.petition.parliament.uk"
      https!
    end

    context "on an unknown provider" do
      let(:provider) { "/admin/auth/unknown" }

      it "redirects to the login page on the passthru url" do
        get "#{provider}"

        expect(response.status).to eq(302)
        expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/login")
        expect(flash[:alert]).to eq("Invalid login details")
      end

      it "redirects to the login page on the callback url" do
        get "#{provider}/callback"

        expect(response.status).to eq(302)
        expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/login")
        expect(flash[:alert]).to eq("Invalid login details")
      end
    end

    context "on a known provider" do
      let(:provider) { "/admin/auth/example" }

      it "redirects to the login page on the passthru url" do
        get "#{provider}"

        expect(response.status).to eq(302)
        expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/login")
        expect(flash[:alert]).to eq("Invalid login details")
      end

      it "redirects to the login page on the callback url" do
        get "#{provider}/callback"

        expect(response.status).to eq(302)
        expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/login")
        expect(flash[:alert]).to eq("Invalid login details")
      end

      context "with invalid auth data" do
        let(:user_attributes) do
          { first_name: "", last_name: "", email: "" }
        end

        let(:login_params) do
          { email: "admin@example.com" }
        end

        it "redirects to the login page" do
          sso_user = FactoryBot.create(:sso_user, **user_attributes)
          OmniAuth.config.mock_auth[:example] = sso_user

          post "/admin/login", params: { user: login_params }

          expect(response.status).to eq(307)
          expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/auth/example")

          follow_redirect!(params: request.POST)

          expect(response.status).to eq(302)
          expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/auth/example/callback")

          follow_redirect!

          expect(response.status).to eq(302)
          expect(response.location).to eq("https://moderate.petition.parliament.uk/admin/login")
          expect(flash[:alert]).to eq("Invalid login details")
        end
      end
    end
  end
end
