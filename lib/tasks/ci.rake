# Custom build task for Continuous Integration.
# see http://blog.josephwilk.net/ruby/cucumber-tags-and-continuous-integration-oh-my.html
begin
require 'cucumber/rake/task'

desc 'Custom Continuous Integration tasks for running RSpec and Cucumber'
task :ci => ['spec_no_rails', 'ci:spec', 'ci:cucumber']

namespace :ci do
  desc 'Custom Continuous Integration task for running RSpec'
  task :spec do
    # Invoke task to run RSpec
    Rake::Task['spec'].invoke
  end

  desc 'Custom Continuous Integration task for running Evergreen'
  task :evergreen do
    Rake::Task['spec:javascripts'].invoke
  end

  desc 'Custom Continuous Integration task for running Cucumber'
  Cucumber::Rake::Task.new(:cucumber) do |t|
    t.cucumber_opts = "--tags ~@javascript"
  end
end

rescue Exception => e
 # staging or production does not know about cucumber
end
