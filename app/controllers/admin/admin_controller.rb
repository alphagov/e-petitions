class Admin::AdminController < ApplicationController
  include Authentication

  before_filter :require_admin_and_check_for_password_change
  layout 'admin'
  helper_method :admin_petition_facets

  protected

  def admin_petition_facets
    I18n.t('admin', scope: :"petitions.facets")
  end

end
