class Admin::AdminController < ApplicationController
  include Authentication, FlashI18n, FlashRender

  skip_before_action :service_unavailable
  skip_before_action :authenticate

  before_action :do_not_cache

  layout 'admin'

  def index
  end
end
