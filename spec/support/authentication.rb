require 'authlogic/test_case'
include Authlogic::TestCase

def login_as(user)
  activate_authlogic
  AdminUserSession.create(user)
end
