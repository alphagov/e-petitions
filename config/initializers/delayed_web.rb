# Tell Delayed::Web that we're using ActiveRecord as our backend.
Rails.application.config.to_prepare do
  Delayed::Web::Job.backend = 'active_record'

  # Authenticate our delayed job web interface
  Delayed::Web::ApplicationController.class_eval do
    include FlashI18n

    before_action :require_admin

    def admin_request?
      true
    end

    protected

    def admin_login_url
      main_app.admin_login_url
    end

    def current_user
      @current_user ||= warden.authenticate(scope: :user)
    end

    def require_admin
      unless current_user
        redirect_to admin_login_url, alert: :admin_required
      end
    end
  end
end
