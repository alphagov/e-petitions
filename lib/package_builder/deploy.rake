# Note that this should not be run with 'bundle exec', as we require
# a different version of aws-sdk to the base app. This is because
# paperclip doesn't yet support aws-sdk > 2.0, while PackageBuilder
# does

# Once Paperclip reaches version 5.0 this can be reverted, and deploy.rake
# can go back into the lib/tasks directory and have the bundler/inline
# changes reverted

require 'tmpdir'
require 'active_support/core_ext/string/strip'
require 'active_support/core_ext/time/calculations'
require 'aws-sdk'
require 'faraday'
require 'slack-notifier'

require_relative 'package_builder'

namespace :deploy do
  desc "Build an application package"
  task :build do
    PackageBuilder.build!
  end

  desc "Build and deploy the website to the dev stack"
  task :dev do
    PackageBuilder.deploy!(:dev)
  end

  desc "Build and deploy the website to the staging stack"
  task :staging do
    PackageBuilder.deploy!(:staging)
  end

  desc "Build and deploy the website to the preview stack"
  task :preview do
    PackageBuilder.deploy!(:preview)
  end

  desc "Build and deploy the website to the production stack"
  task :production do
    PackageBuilder.deploy!(:production)
  end
end

task deploy: 'deploy:staging'
