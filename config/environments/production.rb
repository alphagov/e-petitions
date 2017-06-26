Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Set the HSTS headers to include subdomains
  config.ssl_options[:hsts] = { expires: 365.days, subdomains: true }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Turn on lograge, to give us more parseable logs
  config.lograge.enabled = true

  # Log in logstash format, so that we can easily parse the output
  config.logger = LogStashLogger.new(
    uri: ENV.fetch('LOGSTASH_URI') { 'file://' + Rails.root.join('log', 'production.log').to_s }
  )

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Set default_url_options for links in emails
  config.action_mailer.default_url_options = { host: ENV.fetch('EPETITIONS_HOST') }
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch('SMTP_HOSTNAME'),
    port: ENV.fetch('SMTP_PORT'),
    user_name: ENV.fetch('SMTP_USERNAME'),
    password: ENV.fetch('SMTP_PASSWORD'),
    authentication: :login,
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # For production-like environments we store items in an S3 bucket.
  #
  # However, we don't want to expose the HTTPS urls, since if we ever move to
  # a different hosting platform we don't want to deal with old links.
  # We also don't want to have to get an 'assets.domainname.example' SSL
  # certificate, so instead we proxy requests from the frontend webservers for
  # any url that starts with /attachments/ to the S3 bucket

  config.paperclip_defaults = {
    storage: :fog,
    fog_directory: ENV.fetch('UPLOADED_IMAGES_S3_BUCKET'),
    fog_credentials: {
      use_iam_profile: true,
      provider: 'AWS',
      region: 'eu-west-1',
      scheme: 'https'
    },
    # Proxied to S3 via the webserver
    fog_host: '/attachments'
  }
end
