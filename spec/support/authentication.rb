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

    def http_authentication(username, password)
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    end
  end

  config.include(Devise::Test::ControllerHelpers, type: :controller)
  config.include(mod, type: :controller)
end
