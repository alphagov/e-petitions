source 'https://rubygems.org'

gem 'rails', '4.2.1'

# Legacy Rails feature gems - will no longer be supported in Rails 5.0
gem 'protected_attributes'
gem 'actionpack-action_caching'
gem 'actionpack-page_caching'
gem 'responders'
gem 'rails_autolink'

gem 'rake'
gem 'mysql2'
gem 'authlogic'
gem 'will_paginate'
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'tabnav'
gem 'json'
gem 'memcache-client'
gem 'delayed_job_active_record'
gem 'whenever'
gem 'newrelic_rpm'
gem 'airbrake'
gem 'rabl'
gem 'attr_encrypted'
gem 'dynamic_form'

group :development, :test do
  gem 'rspec-rails'
  gem 'evergreen', :require => 'evergreen/rails'
  gem 'annotate'
  gem 'pry'
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
  gem 'chronic'
  gem 'timecop'
  gem 'launchy'
  gem 'rspec-collection_matchers'
end

group :production do
  gem 'unicorn'
end
