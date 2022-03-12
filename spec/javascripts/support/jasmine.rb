require 'jasmine/runners/selenium'

Jasmine.configure do |config|
  config.prevent_phantom_js_auto_install = true

  chromeArguments = %w[
    headless
    allow-insecure-localhost
    window-size=1280,960
    proxy-server=127.0.0.1:8443
  ]

  if File.exist?("/.dockerenv")
    # Running as root inside Docker
    chromeArguments += %w[no-sandbox disable-gpu]
  end

  config.runner = lambda { |formatter, jasmine_server_url|
    options = Selenium::WebDriver::Chrome::Options.new(args: chromeArguments, w3c: false)
    webdriver = Selenium::WebDriver.for(:chrome, options: options)
    Jasmine::Runners::Selenium.new(formatter, jasmine_server_url, webdriver, 50)
  }
end
