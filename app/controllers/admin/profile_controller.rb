class Admin::ProfileController < Admin::AdminController
  skip_before_filter :check_for_password_change

  def edit
  end

  def update
    if current_user.update_with_password(admin_user_params)
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
