class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  protected

  def sanitise_page_param(param = :page)
    params[param] = params[param].to_i
    params[param] = 1 if params[param] < 1
  end

  def self.caches_action_with_params(*actions)
    options = actions.extract_options!
    options[:cache_path] = Proc.new do |c|
      p = {}
      p[:page] = c.params[:page].to_i unless c.params[:page].blank?
      p[:order] = c.params[:order] unless c.params[:order].blank?
      p[:sort] = c.params[:sort] unless c.params[:sort].blank?
      p[:state] = c.params[:state] unless c.params[:state].blank?
      p
    end
    options[:expires_in] ||= DEFAULT_CACHE_EXPIRY
    actions << options
    self.caches_action(*actions)
  end
end
