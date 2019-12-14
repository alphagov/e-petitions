require 'email_spec/cucumber'
require 'rspec/core/pending'
require 'multi_test'

MultiTest.disable_autorun

Capybara.javascript_driver = ENV.fetch("JS_DRIVER", "chrome_headless").to_sym
Capybara.default_max_wait_time = 5
Capybara.server_port = 3443
Capybara.app_host = "https://127.0.0.1:3443"
Capybara.default_host = "https://petition.parliament.uk"
Capybara.default_selector = :xpath
Capybara.automatic_label_click = true

Capybara.register_driver :chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {
      args: [
        "allow-insecure-localhost",
        "window-size=1280,960",
        "proxy-server=127.0.0.1:8443"
      ],
      w3c: false
    },
    accept_insecure_certs: true
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_driver :chrome_headless do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {
      args: [
        "headless",
        "allow-insecure-localhost",
        "window-size=1280,960",
        "proxy-server=127.0.0.1:8443"
      ],
      w3c: false
    },
    accept_insecure_certs: true
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.register_server :epets do |app, port|
  Epets::SSLServer.build(app, port)
end

Capybara.server = :epets
Capybara.default_normalize_ws = true

pid = Process.spawn('bin/local_proxy', out: 'log/proxy.log', err: 'log/proxy.log')
Process.detach(pid)
at_exit { Process.kill('INT', pid) }

module CucumberI18n
  def t(*args)
    I18n.t(*args)
  end
end

module CucumberSanitizer
  def strip_tags(html)
    @sanitizer ||= Rails::Html::FullSanitizer.new
    @sanitizer.sanitize(html, encode_special_chars: false)
  end
end

World(CucumberI18n)
World(CucumberSanitizer)
World(RejectionHelper)

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
