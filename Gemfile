source :rubygems

gem 'rails', '3.0.12'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'rake', '0.8.7'
gem 'mysql', '2.8.1'
gem 'authlogic', '3.0.3'
gem "will_paginate", "~> 3.0.pre2"
gem 'sunspot_rails', '~> 1.2.1'
gem 'tabnav', :git => 'git://github.com/unboxed/tabnav.git'
gem 'bartt-ssl_requirement', :require => 'ssl_requirement'
gem 'json'
gem 'memcache-client'
gem 'delayed_job', '2.1.4'
gem 'whenever'
gem "rabl"

group :development, :test do
  gem 'rspec-rails'
  # To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
  # gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'ruby-debug'
  gem 'method_info'
  gem 'capistrano-ext'
  gem 'evergreen', :require => 'evergreen/rails'
  gem 'annotate'
end

group :development do
  gem 'mongrel'
  gem 'thin'
end

group :test do
  gem 'nokogiri'
  gem 'shoulda'
  gem 'pickle'
  gem 'cucumber-rails', '~> 0.3.2'
  gem 'database_cleaner'
  gem 'capybara', '~> 1.1.2'
  gem 'selenium-webdriver', '~> 2.5.0'
  gem 'factory_girl_rails'
  gem 'be_valid_asset', :git => 'git://github.com/unboxed/be_valid_asset.git'
  gem 'email_spec', :git => 'git://github.com/bmabey/email-spec.git'
  gem 'chronic', :git => "git://github.com/mojombo/chronic.git"
  gem 'timecop'
  gem 'launchy'
end

# Use unicorn as the web server
group :production do
  gem 'unicorn'
end

# Deploy with Capistrano
# gem 'capistrano'


# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
