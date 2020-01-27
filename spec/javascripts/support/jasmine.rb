require 'jasmine/runners/selenium'

Jasmine.configure do |config|
  config.prevent_phantom_js_auto_install = true

  config.runner = lambda { |formatter, jasmine_server_url|
    options = Selenium::WebDriver::Chrome::Options.new
    options.headless!

    webdriver = Selenium::WebDriver.for(:chrome, options: options)
    Jasmine::Runners::Selenium.new(formatter, jasmine_server_url, webdriver, 50)
  }
end
