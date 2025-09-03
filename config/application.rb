require_relative "../lib/cloud_front_remote_ip"
require_relative "../lib/quiet_logger"
require_relative "../lib/reject_bad_requests"

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Epets
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "London"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join("my", "locales", "*.{rb,yml}").to_s]
    config.i18n.default_locale = :"en-GB"
    config.i18n.fallbacks = %i[en-GB]

    # Configure Active Record to use cache versioning
    config.active_record.cache_versioning = false

    # Disable automatic Active Storage routes
    config.active_storage.draw_routes = false

    # Configure Active Job queue adapter
    config.active_job.queue_adapter = :delayed_job

    # Customise the preload link header
    config.action_view.preload_links_header = false

    # Remove the error wrapper from around the form element
    config.action_view.field_error_proc = -> (html_tag, instance) { html_tag }

    # Add additional exceptions to the rescue responses
    config.action_dispatch.rescue_responses.merge!(
      "IdentityProvider::NotFoundError" => :bad_request,
      "Site::PetitionRemoved" => :gone,
      "Site::ServiceUnavailable" => :service_unavailable,
      "BulkVerification::InvalidBulkRequest" => :bad_request
    )

    config.action_dispatch.default_headers.merge!("X-UA-Compatible" => "IE=edge")

    # Replace ActionDispatch::RemoteIp with our custom middleware
    # to remove the CloudFront ip address from X-Forwarded-For
    config.middleware.insert_before ActionDispatch::RemoteIp, CloudFrontRemoteIp
    config.middleware.delete ActionDispatch::RemoteIp

    # Don't log certain requests that spam the log files
    config.middleware.insert_before Rails::Rack::Logger, QuietLogger, paths: [
      %r[\A/petitions/\d+/count.json\z], %q[/admin/status.json], %q[/ping]
    ]

    # Reject requests with parameters containing null bytes
    config.middleware.insert_before ActionDispatch::Callbacks, RejectBadRequests

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Add application mailer previews path
    config.action_mailer.preview_paths << "#{Rails.root}/app/previews"
  end
end
