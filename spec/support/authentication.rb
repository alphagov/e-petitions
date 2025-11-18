RSpec.configure do |config|
  mod = Module.new do
    def login_as(user)
      sign_in(user, scope: :user)

      # The devise sign_in test helper bypasses the hooks that set
      # the token in the session so we have to set them manually.
      session["warden.user.user.session"] = {
        "persistence_token" => user.persistence_token,
        "last_request_at" => Time.current.to_i
      }
    end

    def http_authentication(options, &block)
      options.reverse_merge!(nc: "00000001", cnonce: "0a4f113b", password_is_ha1: false)
      password = options.delete(:password)
      method = options.delete(:method) || "GET"
      action = options.delete(:action) || :index

      # Make an unauthenticated request to get nonce, opaque, qop and realm attributes
      case method.to_s.upcase
      when "GET"
        get action
      when "POST"
        post action
      end

      expect(response).to have_http_status(401)

      credentials = decode_credentials(response.headers["WWW-Authenticate"])
      credentials.merge!(options)

      path_info = request.env["PATH_INFO"].to_s
      uri = options[:uri] || path_info
      credentials[:uri] = uri

      request.env["ORIGINAL_FULLPATH"] = path_info
      request.env["HTTP_AUTHORIZATION"] = encode_credentials(request.method, credentials, password, options[:password_is_ha1])

      yield
    end

    def encode_credentials(http_method, credentials, password, password_is_ha1 = true)
      ActionController::HttpAuthentication::Digest.encode_credentials(http_method, credentials, password, password_is_ha1)
    end

    def decode_credentials(header)
      ActionController::HttpAuthentication::Digest.decode_credentials(header)
    end
  end

  config.include(Devise::Test::ControllerHelpers, type: :controller)
  config.include(mod, type: :controller)
end
