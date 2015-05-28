mod = Module.new

RSpec.configure do |config|
  config.before(:each, type: :controller) do
    request.env['HTTP_HOST']   = 'petition.parliament.uk'
    request.env['SERVER_PORT'] = 443
    request.env['HTTPS']       = 'on'
  end
end
