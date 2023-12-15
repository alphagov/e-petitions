class Admin::SessionsController < Devise::SessionsController
  skip_before_action :require_admin, except: :continue
  prepend_before_action :skip_timeout, only: :status

  helper_method :last_request_at

  def continue
    respond_to do |format|
      format.json
    end
  end

  def status
    respond_to do |format|
      format.json
    end
  end

  private

  def skip_timeout
    request.env['devise.skip_trackable'] = true
  end

  def last_request_at
    if user_session && user_session.key?("last_request_at")
      Time.at(user_session["last_request_at"]).in_time_zone
    end
  end
end
