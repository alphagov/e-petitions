class Admin::ProfileController < Admin::AdminController
  skip_before_filter :check_for_password_change

  def edit

  end

  def update
    # reset attributes that could be forcing a user to change their password
    current_user.password_changed_at = Time.current
    current_user.force_password_reset = false

    update_params = admin_user_params_for_update

    if ! current_user.valid_password?(current_password)
      current_user.errors.add(:current_password, "is incorrect")
    elsif current_password == params[:admin_user][:password]
      current_user.errors.add(:password, "is the same as the current password")
    elsif update_params[:password].present? and current_user.update_attributes(update_params)
      flash[:notice] = "Password was successfully updated"
      redirect_to admin_root_url and return
    end
    render :edit
  end

  def current_password
    params.require(:admin_user).fetch(:current_password, '')
  end

  def admin_user_params_for_update
    params.
      require(:admin_user).
      permit(:password, :password_confirmation)
  end
end
