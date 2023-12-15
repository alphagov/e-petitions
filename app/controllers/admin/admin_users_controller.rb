class Admin::AdminUsersController < Admin::AdminController
  before_action :require_sysadmin

  def index
    @users = AdminUser.by_name.paginate(page: params[:page], per_page: 50)
  end
end
