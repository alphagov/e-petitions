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

  context "when logged in as an admin" do
    let(:user_attributes) do
      {
        first_name: "System",
        last_name: "Administrator",
        email: "admin@petition.parliament.uk"
      }
    end

    let(:login_params) do
      { email: "admin@petition.parliament.uk", password: "L3tme1n!" }
    end

    let!(:user) { FactoryBot.create(:sysadmin_user, user_attributes) }

    before do
      host! "moderate.petition.parliament.uk"
      https!

      post "/admin/user_sessions", params: { admin_user_session: login_params }
    end

    context "and uploading a debate outcome image" do
      let!(:petition) { FactoryBot.create(:debated_petition) }
      let!(:image) { fixture_file_upload('debate_outcome/blank_image-2x.jpg') }

      it 'does not return 400 for an image containing null bytes' do
        patch "/admin/petitions/#{petition.id}/debate-outcome", params: { debate_outcome: { image: image } }
        expect(response.status).to eq 302
      end
    end
  end
end
