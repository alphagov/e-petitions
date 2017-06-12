require_relative 'boot'

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

    # Configure the cache store
    config.cache_store = :atomic_dalli_store, nil, {
      namespace: 'epets', expires_in: 1.day, compress: true,
      pool_size: ENV.fetch('WEB_CONCURRENCY_MAX_THREADS') { 32 }.to_i
    }

    # Configure Active Job queue adapter
    config.active_job.queue_adapter = :delayed_job

    # Remove the error wrapper from around the form element
    config.action_view.field_error_proc = -> (html_tag, instance) { html_tag }

    # Add 503 Service Unavailable to the rescue response
    config.action_dispatch.rescue_responses.merge!(
      'Site::ServiceUnavailable' => :service_unavailable
    )

    config.action_dispatch.default_headers.merge!('X-UA-Compatible' => 'IE=edge')

  end
end
