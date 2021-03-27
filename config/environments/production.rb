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

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

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
  config.force_ssl = true

  # Set the HSTS headers to include subdomains
  config.ssl_options[:hsts] = { expires: 365.days, subdomains: true }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Turn on lograge, to give us more parseable logs
  config.lograge.enabled = true
  config.lograge.ignore_actions = %w[
    PetitionsController#count
    PingController#ping
    Admin::UserSessionsController#status
    Admin::LocksController#show
    Admin::LocksController#create
    Admin::LocksController#update
    Admin::LocksController#destroy
  ]

  config.lograge.custom_payload do |controller|
    controller.admin_request? ? { user_id: controller.current_user.try(:id) } : {}
  end

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
  config.action_mailer.default_url_options = { host: ENV.fetch('EPETITIONS_HOST_EN') }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :file
  config.action_mailer.perform_deliveries = false

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
    storage: :s3,
    s3_region: 'eu-west-1',
    s3_credentials: {
      bucket: ENV.fetch('UPLOADED_IMAGES_S3_BUCKET')
    },
    path: '/:class/:attachment/:id_partition/:style/:filename',
    url: ':s3_attachment_url'
  }
end
