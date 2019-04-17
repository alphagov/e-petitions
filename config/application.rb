require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Epets
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'London'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :'en-GB'

    # Use SQL for the schema format
    config.active_record.schema_format = :sql

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Configure the cache store
    config.cache_store = :atomic_dalli_store, nil, {
      namespace: 'epets', expires_in: 1.day, compress: true,
      pool_size: ENV.fetch('WEB_CONCURRENCY_MAX_THREADS') { 32 }.to_i
    }

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

    # Configure CloudFront trusted proxies for RemoteIp middleware
    config.action_dispatch.trusted_proxies = %w[
      10.0.0.0/8 13.32.0.0/15 13.35.0.0/16 13.224.0.0/14 13.249.0.0/16
      52.46.0.0/18 52.82.128.0/19 52.84.0.0/15 52.124.128.0/17
      52.212.248.0/26 52.222.128.0/17 54.182.0.0/16 54.192.0.0/16
      54.230.0.0/16 54.239.128.0/18 54.239.192.0/19 54.240.128.0/18
      64.252.64.0/18 64.252.128.0/18 70.132.0.0/18 71.152.0.0/17
      99.84.0.0/16 99.86.0.0/16 130.176.0.0/16 143.204.0.0/16
      144.220.0.0/16 204.246.164.0/22 204.246.168.0/22 204.246.172.0/23
      204.246.174.0/23 204.246.176.0/20 205.251.192.0/19 205.251.249.0/24
      205.251.250.0/23 205.251.252.0/23 205.251.254.0/24 216.137.32.0/19
    ]
  end
end
