class Admin::AdminController < ApplicationController
  include Authentication

  before_action :do_not_cache

  layout 'admin'

  def index
  end

end
