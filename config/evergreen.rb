require 'capybara/poltergeist'

Evergreen.configure do |config|
  config.driver = :poltergeist
end
