class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_seen_cookie_message, if: :show_cookie_message?
  helper_method :show_cookie_message?

  protected

  def set_seen_cookie_message
    cookies[:seen_cookie_message] = { value: 'yes', expires: 1.year.from_now }
  end

  def show_cookie_message?
    @show_cookie_message ||= cookies[:seen_cookie_message] != 'yes'
  end
end
