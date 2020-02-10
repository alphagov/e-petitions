RSpec.configure do |config|
  config.before(:each, type: :controller) do |example|
    if example.metadata[:admin]
      request.env['HTTP_HOST'] = Site.moderate_host
    elsif example.metadata[:welsh]
      request.env['HTTP_HOST'] = Site.host_cy
    else
      request.env['HTTP_HOST'] = Site.host_en
    end

    request.env['SERVER_PORT'] = Site.port
    request.env['HTTPS']       = 'on'
  end

  config.before(:each, type: :request) do |example|
    if example.metadata[:admin]
      host! Site.moderate_host_with_port
    elsif example.metadata[:welsh]
      host! Site.host_with_port_cy
    else
      host! Site.host_with_port_en
    end

    https!
  end
end
