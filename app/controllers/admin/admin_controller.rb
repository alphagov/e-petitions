class Admin::AdminController < ApplicationController
  include Authentication

  before_action :require_admin_and_check_for_password_change
  before_action :do_not_cache

  layout 'admin'

  helper_method :admin_petition_facets

  def index
  end

  protected

  def admin_petition_facets
    I18n.t('admin', scope: :"petitions.facets")
  end

end
