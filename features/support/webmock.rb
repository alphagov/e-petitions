require 'webmock'

WebMock.disable_net_connect!(allow_localhost: true,
                             allow: %w{validator.unboxedconsulting.com})
