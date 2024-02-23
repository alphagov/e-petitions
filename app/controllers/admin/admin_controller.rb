class Admin::AdminController < ApplicationController
  include Authentication, FlashRender

  skip_before_action :service_unavailable
  skip_before_action :authenticate

  before_action :set_appsignal_namespace
  before_action :do_not_cache
  before_action :set_current_user

  layout 'admin'

  def index
  end

  def admin_request?
    true
  end

  private

  def set_appsignal_namespace
    Appsignal.set_namespace("admin")
  end

  def set_current_user
    Admin::Current.user = current_user
  end

  def after_sign_in_path_for(resource)
    admin_root_url
  end

  def after_sign_out_path_for(resource)
    admin_login_url
  end
end
