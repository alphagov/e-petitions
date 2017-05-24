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

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = !ENV['DISABLE_SSL'].present?

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
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Set default_url_options for links in emails
  config.action_mailer.default_url_options = { host: ENV.fetch('EPETITIONS_HOST') }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { address: ENV.fetch('SMTP_HOSTNAME'), port: ENV.fetch('SMTP_PORT') }
  config.action_mailer.smtp_settings[:user_name] = ENV['SMTP_USERNAME'] if ENV.key?('SMTP_USERNAME')
  config.action_mailer.smtp_settings[:password] = ENV['SMTP_PASSWORD'] if ENV.key?('SMTP_PASSWORD')
  config.action_mailer.smtp_settings[:authentication] = ENV['SMTP_AUTH'].to_sym if ENV.key?('SMTP_AUTH')
  config.action_mailer.smtp_settings[:enable_starttls_auto] = ENV['SMTP_USERNAME'].present?

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

  if ENV.key?('UPLOADED_IMAGES_S3_BUCKET')
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
end
