require 'authlogic/test_case'
include Authlogic::TestCase

def login_as(user)
  activate_authlogic
  AdminUserSession.create(user)
end

def http_authentication(username, password)
  request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
end
