require File.expand_path('../boot', __FILE__)
require File.expand_path('../../lib/cloud_front_remote_ip', __FILE__)
require File.expand_path('../../lib/quiet_logger', __FILE__)

require 'rails'

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Epets
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'London'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :'en-GB'
    config.i18n.fallbacks = %i[en-GB]

    # config.eager_load_paths << Rails.root.join("extras")

    # Configure the cache store
    config.cache_store = :mem_cache_store, nil, {
      expires_in: 1.day, compress: true,
      namespace: ENV.fetch('MEMCACHE_NAMESPACE') { 'epets' },
      pool_size: ENV.fetch('WEB_CONCURRENCY_MAX_THREADS') { 32 }.to_i
    }

    # Configure Active Record to use cache versioning
    config.active_record.cache_versioning = false

    # Disable automatic Active Storage routes
    config.active_storage.draw_routes = false

    # Configure Active Job queue adapter
    config.active_job.queue_adapter = :delayed_job

    # Remove the error wrapper from around the form element
    config.action_view.field_error_proc = -> (html_tag, instance) { html_tag }

    # Add additional exceptions to the rescue responses
    config.action_dispatch.rescue_responses.merge!(
      'Site::ServiceUnavailable' => :service_unavailable,
      'BulkVerification::InvalidBulkRequest' => :bad_request
    )

    config.action_dispatch.default_headers.merge!('X-UA-Compatible' => 'IE=edge')

    # Needed as Rails does not add app/jobs/concerns to the load path
    config.paths.add 'app/jobs/concerns', eager_load: true

    # Replace ActionDispatch::RemoteIp with our custom middleware
    # to remove the CloudFront ip address from X-Forwarded-For
    config.middleware.insert_before ActionDispatch::RemoteIp, CloudFrontRemoteIp
    config.middleware.delete ActionDispatch::RemoteIp

    # Don't log certain requests that spam the log files
    config.middleware.insert_before Rails::Rack::Logger, QuietLogger, paths: [
      %r[\A/petitions/\d+/count.json\z], %q[/admin/status.json], %q[/ping]
    ]

    # Generate integer primary keys
    config.generators do |generator|
      generator.orm :active_record, primary_key_type: :serial
    end
  end
end
