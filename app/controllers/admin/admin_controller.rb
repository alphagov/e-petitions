class Admin::AdminController < ApplicationController
  include Authentication

  before_action :require_admin_and_check_for_password_change
  before_action :do_not_cache

  layout 'admin'

  def index
  end

end
