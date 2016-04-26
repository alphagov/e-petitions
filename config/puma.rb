# Pumacorn specific items:
application_name = "epetitions"
pidfile "/home/deploy/#{application_name}/shared/pids/puma.pid"
bind "unix:///var/run/pumacorn/#{application_name}.sock"

# Based on https://raw.githubusercontent.com/codetriage/codetriage/master/config/puma.rb
concurrency = {
  # Set to default of 4 workers - c4.xlarge has 4 CPUs
  workers: ENV.fetch('WEB_CONCURRENCY') { 4 }.to_i,
  # Some experimentation seems to indicate these are reasonable options:
  min_threads: ENV.fetch('WEB_CONCURRENCY_MIN_THREADS') { 16 }.to_i,
  max_threads: ENV.fetch('WEB_CONCURRENCY_MAX_THREADS') { 32 }.to_i
}

workers(concurrency[:workers])
threads(concurrency[:min_threads], concurrency[:max_threads])

preload_app!

on_worker_boot do
  # Reset the connection to the cache if we can
  Rails.cache.reset if Rails.cache.respond_to?(:reset)

  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
