require 'health_check_middleware'
# Go before the first middleware that might touch the db
Rails.application.config.middleware.insert_after ActionDispatch::Callbacks, HealthCheckMiddleware
