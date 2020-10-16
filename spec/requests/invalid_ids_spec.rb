require 'rails_helper'

RSpec.describe "invalid ids", type: :request, show_exceptions: true, csrf: false do
  context "when on the English website" do
    describe "GET /petitions/:id" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:id/count.json" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number/count.json"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:id/gathering-support" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number/gathering-support"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:id/moderation-info" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number/moderation-info"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:petition_id/sponsors/new" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number/sponsors/new"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /petitions/:petition_id/sponsors/new" do
      it "returns a 400 Bad Request" do
        post "/petitions/not-a-number/sponsors/new"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /petitions/:petition_id/sponsors" do
      it "returns a 400 Bad Request" do
        post "/petitions/not-a-number/sponsors"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:petition_id/sponsors/thank-you" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number/sponsors/thank-you"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /sponsors/:id/verify" do
      it "returns a 400 Bad Request" do
        get "/sponsors/not-a-number/verify"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /sponsors/:id/sponsored" do
      it "returns a 400 Bad Request" do
        get "/sponsors/not-a-number/sponsored"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:petition_id/signatures/new" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number/signatures/new"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /petitions/:petition_id/signatures/new" do
      it "returns a 400 Bad Request" do
        post "/petitions/not-a-number/signatures/new"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /petitions/:petition_id/signatures" do
      it "returns a 400 Bad Request" do
        post "/petitions/not-a-number/signatures"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:petition_id/signatures/thank-you" do
      it "returns a 400 Bad Request" do
        get "/petitions/not-a-number/signatures/thank-you"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /signatures/:id/verify" do
      it "returns a 400 Bad Request" do
        get "/signatures/not-a-number/verify"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /signatures/:id/signed" do
      it "returns a 400 Bad Request" do
        get "/signatures/not-a-number/signed"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /signatures/:id/unsubscribe" do
      it "returns a 400 Bad Request" do
        get "/signatures/not-a-number/unsubscribe"
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  context "when on the Welsh website", welsh: true do
    describe "GET /deisebau/:id" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /deisebau/:id/cyfrif.json" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif/cyfrif.json"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /deisebau/:id/casglu-cefnogaeth" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif/casglu-cefnogaeth"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /deisebau/:id/cymedroli-gwybodaeth" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif/cymedroli-gwybodaeth"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /deisebau/:petition_id/noddwyr/newydd" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif/noddwyr/newydd"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /deisebau/:petition_id/noddwyr/newydd" do
      it "returns a 400 Bad Request" do
        post "/deisebau/nid-rhif/noddwyr/newydd"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /deisebau/:petition_id/noddwyr" do
      it "returns a 400 Bad Request" do
        post "/deisebau/nid-rhif/noddwyr"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /deisebau/:petition_id/noddwyr/diolch" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif/noddwyr/diolch"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /noddwyr/:id/gwirio" do
      it "returns a 400 Bad Request" do
        get "/noddwyr/nid-rhif/gwirio"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /noddwyr/:id/noddedig" do
      it "returns a 400 Bad Request" do
        get "/noddwyr/nid-rhif/noddedig"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /deisebau/:petition_id/llofnodion/newydd" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif/llofnodion/newydd"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /deisebau/:petition_id/llofnodion/newydd" do
      it "returns a 400 Bad Request" do
        post "/deisebau/nid-rhif/llofnodion/newydd"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "POST /deisebau/:petition_id/llofnodion" do
      it "returns a 400 Bad Request" do
        post "/deisebau/nid-rhif/llofnodion"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /deisebau/:petition_id/llofnodion/diolch" do
      it "returns a 400 Bad Request" do
        get "/deisebau/nid-rhif/llofnodion/diolch"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /llofnodion/:id/gwirio" do
      it "returns a 400 Bad Request" do
        get "/llofnodion/nid-rhif/gwirio"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /llofnodion/:id/llofnodwyd" do
      it "returns a 400 Bad Request" do
        get "/llofnodion/nid-rhif/llofnodwyd"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /llofnodion/:id/dad-danysgrifio" do
      it "returns a 400 Bad Request" do
        get "/llofnodion/nid-rhif/dad-danysgrifio"
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
