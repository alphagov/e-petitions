class Admin::AdminController < ApplicationController
  include Authentication
  # makes all actions ssl protected
  ssl_exceptions
  
  before_filter :require_admin_and_check_for_password_change
  layout 'admin'
  
end