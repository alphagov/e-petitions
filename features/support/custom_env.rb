require 'email_spec/cucumber'
require 'rspec/core/pending'
require 'rspec/mocks'
require 'multi_test'
require 'faker'

MultiTest.disable_autorun

Capybara.javascript_driver = ENV.fetch("JS_DRIVER", "chrome_headless").to_sym
Capybara.default_max_wait_time = 5
Capybara.server_port = 3443
Capybara.app_host = "https://127.0.0.1:3443"
Capybara.default_host = "https://petition.parliament.uk"
Capybara.default_selector = :xpath
Capybara.automatic_label_click = true

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.accept_insecure_certs = true

    opts.add_argument('--allow-insecure-localhost')
    opts.add_argument('--window-size=1280,960')
    opts.add_argument('--proxy-server=127.0.0.1:8443')

    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument('--disable-site-isolation-trials')
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.accept_insecure_certs = true

    opts.add_argument('--headless')
    opts.add_argument('--allow-insecure-localhost')
    opts.add_argument('--window-size=1280,960')
    opts.add_argument('--proxy-server=127.0.0.1:8443')

    if File.exist?("/.dockerenv")
      # Running as root inside Docker
      opts.add_argument('--no-sandbox')
      opts.add_argument('--disable-gpu')
    end

    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument('--disable-site-isolation-trials')
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_server :epets do |app, port|
  Epets::SSLServer.build(app, port)
end

Capybara.server = :epets
Capybara.default_normalize_ws = true

pid = Process.spawn('bin/local_proxy', out: 'log/proxy.log', err: 'log/proxy.log')
Process.detach(pid)

at_exit { Process.kill('INT', pid) rescue nil }

module CucumberI18n
  def t(*args)
    I18n.t(*args)
  end
end

module CucumberSanitizer
  def sanitize(html, options = {})
    @safe_list_sanitizer ||= Rails::Html::SafeListSanitizer.new
    @safe_list_sanitizer.sanitize(html, options).html_safe
  end

  def strip_tags(html)
    @full_sanitizer ||= Rails::Html::FullSanitizer.new
    @full_sanitizer.sanitize(html, encode_special_chars: false)
  end
end

module CucumberHelpers
  def click_details(name)
    if Capybara.current_driver == Capybara.javascript_driver
      page.find("//details/summary[contains(., '#{name}')]").click
    else
      page.find("//summary[contains(., '#{name}')]/..").click
    end
  end
end

World(CucumberI18n)
World(CucumberHelpers)
World(CucumberSanitizer)
World(MarkdownHelper)
World(RejectionHelper)
World(RSpec::Mocks::ExampleMethods)

# run background jobs inline with delayed job
ActiveJob::Base.queue_adapter = :delayed_job
Delayed::Worker.delay_jobs = false


# Monkey patch Cucumber::Rails to accept Capybara 3.x changes
# https://github.com/cucumber/cucumber-rails/commit/286f37f
module Cucumber
  module Rails
    module Capybara
      module JavascriptEmulation
        def click_with_javascript_emulation(*)
          if link_with_non_get_http_method?
            ::Capybara::RackTest::Form.new(driver, js_form(element_node.document, self[:href], emulated_method)).submit(self)
          else
            click_without_javascript_emulation
          end
        end
      end
    end
  end
end
