class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  protected

  def sanitise_page_param(param = :page)
    params[param] = params[param].to_i
    params[param] = 1 if params[param] < 1
  end
end
