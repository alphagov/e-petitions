require 'email_spec/cucumber'
require 'rspec/core/pending'
require 'capybara/poltergeist'
require 'webrick/httpproxy'

Capybara.javascript_driver = :poltergeist
Capybara.default_max_wait_time = 5
Capybara.server_port = 3443
Capybara.app_host = "https://127.0.0.1:3443"
Capybara.default_host = "https://petition.parliament.uk"
Capybara.default_selector = :xpath

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    phantomjs_logger: "/dev/null",
    phantomjs_options: [
      '--ignore-ssl-errors=yes',
      '--local-to-remote-url-access=yes',
      '--proxy=127.0.0.1:8443'
    ]
  )
end

Capybara.server do |app, port|
  Epets::SSLServer.build(app, port)
end

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
