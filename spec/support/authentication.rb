require 'authlogic/test_case'

RSpec.configure do |config|
  mod = Module.new do
    def login_as(user)
      activate_authlogic
      AdminUserSession.create(user)
    end

    def http_authentication(username, password)
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    end
  end

  config.include(mod, type: :controller)
  config.include(Authlogic::TestCase, type: :controller)
end
