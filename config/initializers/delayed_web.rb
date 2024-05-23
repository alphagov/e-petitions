# Tell Delayed::Web that we're using ActiveRecord as our backend.
Rails.application.config.to_prepare do
  Delayed::Web::Job.backend = 'active_record'

  # Authenticate our delayed job web interface
  Delayed::Web::ApplicationController.class_eval do
    include FlashI18n

    rescue_from ActiveRecord::RecordNotFound do
      redirect_to root_url, notice: t(:notice, scope: 'delayed/web.flashes.jobs.not_found')
    end

    before_action :require_admin

    def admin_request?
      true
    end

    protected

    def admin_login_url
      main_app.admin_login_url
    end

    def require_admin
      unless current_user
        redirect_to admin_login_url, alert: :admin_required
      end
    end
  end
end
