RSpec.configure do |config|
  config.before(:each, type: :controller) do
    request.env['HTTP_HOST']   = 'petition.parliament.uk'
    request.env['SERVER_PORT'] = 443
    request.env['HTTPS']       = 'on'
  end

  config.before(:each, type: :request) do
    https!
    host! 'petition.parliament.uk'
  end
end
