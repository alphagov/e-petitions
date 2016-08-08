# Tell Delayed::Web that we're using ActiveRecord as our backend.
Rails.application.config.to_prepare do
  Delayed::Web::Job.backend = 'active_record'
end

# Authenticate our delayed job web interface
Delayed::Web::ApplicationController.class_eval do
  include Authentication

  def admin_login_url
    main_app.admin_login_url
  end
end
