require 'rails_helper'

RSpec.describe "Content Security Policy header", type: :request do
  subject { response.header["Content-Security-Policy"] }

  context "when calling a default page" do
    before do
      get "/ping"
    end

    it "sets default-src to 'self'" do
      expect(subject).to match(/\Adefault-src 'self';/)
    end

    it "sets connect-src to 'self'" do
      expect(subject).to match(/connect-src 'self';/)
    end

    it "sets img-src to 'self'" do
      expect(subject).to match(/img-src 'self';/)
    end

    it "sets script-src to 'self' and 'unsafe-inline'" do
      expect(subject).to match(/script-src 'self' 'unsafe-inline';/)
    end

    it "sets style-src to 'self' and 'unsafe-inline'" do
      expect(subject).to match(/style-src 'self' 'unsafe-inline'\z/)
    end
  end

  context "when calling a public page" do
    context "and Google Analytics is disabled" do
      before do
        get "/"
      end

      it "sets default-src to 'self'" do
        expect(subject).to match(/\Adefault-src 'self';/)
      end

      it "sets connect-src to 'self'" do
        expect(subject).to match(/connect-src 'self';/)
      end

      it "sets img-src to 'self'" do
        expect(subject).to match(/img-src 'self';/)
      end

      it "sets script-src to 'self'" do
        expect(subject).to match(/script-src 'self';/)
      end

      it "sets style-src to 'self' and 'unsafe-inline'" do
        expect(subject).to match(/style-src 'self' 'unsafe-inline'\z/)
      end
    end

    context "and Google Analytics is enabled" do
      let(:google_tag_manager_id) { "GTM-5DJ37LLQ" }
      let(:google_tag_manager_hash) { "sha256-3x3Cf3BpConmX9H6jQnu7fl/JZFKixTF8zDhtuQhCGg=" }

      before do
        allow(Site).to receive(:enable_analytics?).and_return(true)
        allow(Site).to receive(:google_tag_manager_id).and_return(google_tag_manager_id)
        allow(Site).to receive(:google_tag_manager_hash).and_return(google_tag_manager_hash)

        get "/"
      end

      it "sets default-src to 'self'" do
        expect(subject).to match(/\Adefault-src 'self';/)
      end

      it "sets connect-src to 'self', https://*.google-analytics.com, https://*.analytics.google.com and https://*.googletagmanager.com" do
        expect(subject).to match(/connect-src 'self' https:\/\/\*\.google-analytics\.com https:\/\/\*\.analytics\.google\.com https:\/\/\*\.googletagmanager\.com;/)
      end

      it "sets img-src to 'self', https://*.google-analytics.com and https://*.googletagmanager.com" do
        expect(subject).to match(/img-src 'self' https:\/\/\*\.google-analytics\.com https:\/\/\*\.googletagmanager\.com;/)
      end

      it "sets script-src to 'self', https://*.googletagmanager.com and the GTM hash" do
        expect(subject).to match(/script-src 'self' https:\/\/\*\.googletagmanager\.com 'sha256-3x3Cf3BpConmX9H6jQnu7fl\/JZFKixTF8zDhtuQhCGg=';/)
      end

      it "sets style-src to 'self' and 'unsafe-inline'" do
        expect(subject).to match(/style-src 'self' 'unsafe-inline';/)
      end

      it "sets frame-src to 'self', https://*.google-analytics.com and https://*.googletagmanager.com" do
        expect(subject).to match(/frame-src 'self' https:\/\/\*\.google-analytics\.com https:\/\/\*\.googletagmanager\.com\z/)
      end
    end
  end

  context "when calling an admin page", admin: true do
    let(:nonce_generator) { Admin::AdminController::NONCE_GENERATOR }

    before do
      allow(nonce_generator).to receive(:call).and_return("ZXhHDy3TnT4lgIMeEyq2")

      get "/admin/login"
    end

    it "sets default-src to 'self'" do
      expect(subject).to match(/\Adefault-src 'self';/)
    end

    it "sets connect-src to 'self'" do
      expect(subject).to match(/connect-src 'self';/)
    end

    it "sets img-src to 'self'" do
      expect(subject).to match(/img-src 'self';/)
    end

    it "sets script-src to 'self' and 'nonce-ZXhHDy3TnT4lgIMeEyq2'" do
      expect(subject).to match(/script-src 'self' 'nonce-ZXhHDy3TnT4lgIMeEyq2';/)
    end

    it "sets style-src to 'self' and 'unsafe-inline'" do
      expect(subject).to match(/style-src 'self' 'unsafe-inline'\z/)
    end
  end
end
