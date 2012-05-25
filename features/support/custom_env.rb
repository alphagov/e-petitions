Dir["#{Rails.root}/spec/shared_support/**/*.rb"].each {|f| require f}

require "email_spec"
require 'email_spec/cucumber'