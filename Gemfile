source 'https://rubygems.org'

# Load environment variables
gem 'dotenv-rails', :require => 'dotenv/rails-now'

gem 'rails', '4.2.1'

# Legacy Rails feature gems - will no longer be supported in Rails 5.0
gem 'responders'
gem 'rails_autolink'

gem 'rake'
gem 'pg'
gem 'authlogic'
gem 'will_paginate'
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'tabnav'
gem 'json'
gem 'delayed_job_active_record'
gem 'whenever'
gem 'newrelic_rpm'
gem 'airbrake'
gem 'dynamic_form'
gem 'faraday'
gem 'faraday_middleware'
gem 'sass-rails', '~> 5.0'
gem 'aws-sdk'

group :development, :test do
  gem 'rspec-rails'
  gem 'evergreen', :require => 'evergreen/rails'
  gem 'pry'
  gem 'faker'
end

group :test do
  gem 'nokogiri'
  gem 'shoulda'
  gem 'pickle'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem 'be_valid_asset', :require => false
  gem 'email_spec'
  gem 'launchy'
  gem 'webmock'
end

group :production do
  gem 'puma'
end
