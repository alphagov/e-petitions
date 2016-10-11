class Admin::AdminController < ApplicationController
  include Authentication, FlashI18n, FlashRender

  before_action :do_not_cache

  layout 'admin'

  def index
  end
end
