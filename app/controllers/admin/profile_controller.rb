class Admin::ProfileController < Admin::AdminController
  skip_before_action :check_for_password_change

  def edit
  end

  def update
    if current_user.update_password(admin_user_params)
      bypass_sign_in(current_user, scope: :user)
      redirect_to admin_root_url, notice: :password_updated
    else
      render :edit
    end
  end

  def admin_user_params
    params.require(:admin_user).permit(
      :current_password, :password, :password_confirmation
    )
  end
end
