class AdminUserSession < Authlogic::Session::Base
  allow_http_basic_auth false
  consecutive_failed_logins_limit AdminUser::DISABLED_LOGIN_COUNT

  def last_login_attempt?
    failed_login_count == consecutive_failed_logins_limit - 1
  end

  private

  def failed_login_count
    attempted_record.present? ? attempted_record.failed_login_count : 0
  end
end
