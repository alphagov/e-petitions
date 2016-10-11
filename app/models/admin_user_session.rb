class AdminUserSession < Authlogic::Session::Base
  allow_http_basic_auth false
  consecutive_failed_logins_limit AdminUser::DISABLED_LOGIN_COUNT
  logout_on_timeout true

  before_save do
    record.reset_persistence_token!
  end

  before_destroy do
    if stale?
      stale_record.reset_persistence_token!
    else
      record.reset_persistence_token!
    end
  end

  def last_login_attempt?
    failed_login_count == consecutive_failed_logins_limit - 1
  end

  def time_remaining
    record ? record.time_remaining : 0
  end

  private

  def failed_login_count
    attempted_record.present? ? attempted_record.failed_login_count : 0
  end
end
