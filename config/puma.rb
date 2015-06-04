# Pumacorn specific items:
application_name = "epetitions"
pidfile "/home/deploy/#{application_name}/shared/pids/puma.pid"
bind "unix:///var/run/pumacorn/#{application_name}.sock"

# Based on https://raw.githubusercontent.com/codetriage/codetriage/master/config/puma.rb
workers ENV.fetch('WEB_CONCURRENCY') { 2 }.to_i

preload_app!

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
