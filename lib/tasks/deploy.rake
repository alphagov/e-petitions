require 'package_builder'

namespace :deploy do
  desc "Build an application package"
  task :build do
    PackageBuilder.build!
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
