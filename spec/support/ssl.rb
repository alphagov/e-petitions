RSpec.configure do |config|
  config.before(:each, type: :controller) do |example|
    if example.metadata[:admin]
      request.env['HTTP_HOST'] = Site.moderate_host
    else
      request.env['HTTP_HOST'] = Site.host
    end

    request.env['SERVER_PORT'] = Site.port
    request.env['HTTPS']       = 'on'
  end

  config.before(:each, type: :request) do |example|
    if example.metadata[:admin]
      host! Site.moderate_host_with_port
    else
      host! Site.host_with_port
    end

    https!
  end

  config.before(:each, type: :feature) do
    Capybara.app_host     = Site.url
    Capybara.default_host = Site.url
  end

  config.before(:each, type: :feature, admin: true) do
    Capybara.app_host     = Site.moderate_url
    Capybara.default_host = Site.moderate_url
  end
end
