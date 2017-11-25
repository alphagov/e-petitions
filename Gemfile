source 'https://rubygems.org'

# Load environment variables
gem 'dotenv-rails', :require => 'dotenv/rails-now'

gem 'rails', '4.2.10'

gem 'rake'
gem 'pg'
gem 'authlogic'
gem 'will_paginate'
gem 'json'
gem 'delayed_job_active_record'
gem 'whenever'
gem 'appsignal'
gem 'dynamic_form'
gem 'faraday'
gem 'faraday_middleware'
gem 'net-http-persistent'
gem 'sass-rails', '~> 5.0'
gem 'textacular'
gem 'uglifier'
gem 'bcrypt'
gem 'faker'
gem 'slack-notifier'
gem 'daemons'
gem 'jquery-rails'
gem 'delayed-web'
gem 'dalli'
gem 'connection_pool'
gem 'lograge'
gem 'logstash-logger'
gem 'jbuilder'
gem 'paperclip'
gem 'maxminddb'

# Two AWS libraries:
#   - aws-sdk v2 for CodeDeploy, which neither Fog nor aws-sdk v1 support
#   - fog for image uploads, as Paperclip doesn't support aws-sdk v2
gem 'aws-sdk', '~> 2.0'
gem 'fog-aws', '~> 1.0'

group :development, :test do
  gem 'rspec-rails'
  gem 'jasmine-rails'
  gem 'pry'
end

group :test do
  gem 'nokogiri'
  gem 'shoulda-matchers'
  gem 'pickle'
  gem 'cucumber', '~> 2.4.0'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_bot_rails'
  gem 'email_spec'
  gem 'launchy'
  gem 'webmock'
end

group :production do
  gem 'puma'
end
