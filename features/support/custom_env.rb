require 'email_spec/cucumber'
require 'rspec/core/pending'
require 'be_valid_asset'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 5
Capybara.server_port = 3443
Capybara.app_host = "https://localhost:3443"
Capybara.default_host = "https://localhost"

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    :phantomjs_options => [
      '--ignore-ssl-errors=yes',
      '--local-to-remote-url-access=yes'
    ]
  )
end

Capybara.server do |app, port|
  Epets::SSLServer.build(app, port)
end

World(BeValidAsset)

BeValidAsset::Configuration.markup_validator_host = 'validator.unboxedconsulting.com'
BeValidAsset::Configuration.css_validator_host = 'validator.unboxedconsulting.com'
BeValidAsset::Configuration.feed_validator_host = 'validator.unboxedconsulting.com'
BeValidAsset::Configuration.enable_caching = true
BeValidAsset::Configuration.cache_path = File.join(Rails.root.to_s, %w(tmp be_valid_asset_cache))
BeValidAsset::Configuration.display_invalid_lines = true
