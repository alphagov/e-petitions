# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Epets::Application.load_tasks

task(:default).clear_prerequisites
task :default => [:spec_no_rails, :spec, :'spec:javascripts', :'cucumber']
