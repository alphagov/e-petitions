# From https://gist.github.com/466411 & https://github.com/jnicklas/capybara/issues#issue/85
# Note, JP removed a :get from the array on line 6 as it caused the search by free text feature to fail.

module Capybara::Driver::RackTest::SslFix

  [:post, :put, :delete].each do |method|
    define_method method do |*args|
      args[0] = path_to_ssl_aware_url(args[0])
      super(*args)
    end
  end

  private

  def path_to_ssl_aware_url(path)
    unless path =~ /:\/\//
      env = request.env
      path = "#{env["rack.url_scheme"]}://#{env["SERVER_NAME"]}#{path}"
    end
    path
  rescue Rack::Test::Error
    # no request yet
    path
  end

end

Capybara::Driver::RackTest.send :include, Capybara::Driver::RackTest::SslFix