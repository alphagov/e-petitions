Devise.setup do |config|
  # ==> Controller configuration
  config.parent_controller = 'Admin::AdminController'

  # ==> Mailer Configuration
  config.mailer_sender = 'petitionscommittee@parliament.uk'
  config.mailer = 'Devise::Mailer'
  config.parent_mailer = 'ActionMailer::Base'

  # ==> ORM configuration
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  config.authentication_keys = [:email]
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  # ==> Configuration for :timeoutable
  # This is overidden on the AdminUser model to use Site.login_timeout
  config.timeout_in = 24.hours

  # ==> Navigation configuration
  config.sign_out_via = :get

  # ==> Omniauth configuration
  config.omniauth_path_prefix = '/admin/auth'
  config.omniauth :developer, fields: %i[email]

  # ==> Warden configuration
  # Reset the token after logging in so that other sessions are logged out
  Warden::Manager.after_set_user except: :fetch do |user, warden, options|
    if warden.authenticated?(:user)
      session = warden.session(:user)
      session['persistence_token'] = user.reset_persistence_token!
    end
  end

  # Logout the user if the token doesn't match what's in the session
  Warden::Manager.after_set_user only: :fetch do |user, warden, options|
    if warden.authenticated?(:user) && options[:store] != false
      session = warden.session(:user)

      unless user.valid_persistence_token?(session['persistence_token'])
        warden.raw_session.clear
        warden.logout(:user)

        throw :warden, scope: :user, message: :other_login
      end
    end
  end

  # The devise failure app redirects to self when a session times out
  # which causes issues with flash messages, etc. so change the message
  # in the options hash to trigger the alternative path.
  Warden::Manager.before_failure do |env, options|
    if options[:message] == :timeout
      options[:message] = :timedout
    end
  end

  # Reset the token after logging out
  Warden::Manager.before_logout do |user, warden, options|
    user && user.reset_persistence_token!
  end
end
