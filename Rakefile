# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Rails.application.load_tasks

task(:default).clear_prerequisites

task default: %i[
  bundle:audit brakeman:check
  spec spec:javascripts cucumber
]
