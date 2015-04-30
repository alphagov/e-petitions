require 'capybara/poltergeist'

Evergreen.configure do |config|
  config.driver = :poltergeist
  config.application = Evergreen::Application
  config.mounted_at = ''
end
