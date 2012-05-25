class AdminUserSession < Authlogic::Session::Base
  allow_http_basic_auth false
  consecutive_failed_logins_limit AdminUser::DISABLED_LOGIN_COUNT

end
