class Admin::AdminController < ApplicationController
  include Authentication, FlashI18n, FlashRender

  before_action :do_not_cache
  before_action :find_admin_settings

  layout 'admin'

  def index
  end

  private

  def find_admin_settings
    @admin_settings ||= Admin::Settings.first_or_create!
  end
end
