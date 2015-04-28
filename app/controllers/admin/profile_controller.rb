class Admin::ProfileController < Admin::AdminController
  skip_before_filter :require_admin_and_check_for_password_change
  before_filter :require_admin

  def edit

  end

  def update
    # reset attributes that could be forcing a user to change their password
    current_user.password_changed_at = Time.zone.now
    current_user.force_password_reset = false

    if ! current_user.valid_password?(params[:current_password])
      current_user.errors.add(:current_password, "is incorrect")
    elsif params[:current_password] == params[:admin_user][:password]
      current_user.errors.add(:password, "is the same as the current password")
    elsif params[:admin_user][:password].present? and current_user.update_attributes(params[:admin_user])
      flash[:notice] = "Password was successfully updated"
      redirect_to admin_root_path and return
    end
    render :edit
  end
end
