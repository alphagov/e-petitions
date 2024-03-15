module RequestRoutingMatchers
  URL_PARAMS = %w[protocol host port domain subdomain]

  class RouteToMatcher
    attr_reader :scope, :expected

    delegate :request, :response, to: :scope
    delegate :params, :path, to: :request
    delegate :location, :successful?, :redirect?, to: :response

    def initialize(scope, *expected)
      @expected = expected[1] || {}
      @scope = scope

      if Hash === expected[0]
        @expected.merge!(expected[0])
      else
        controller, action = expected[0].split('#')
        @expected.merge!(:controller => controller, :action => action)
      end

      @expected.stringify_keys!
    end

    def matches?(actual)
      process(actual) if Hash === actual
      successful? && !redirect? && params_match?
    end

    def process(request)
      method, path = request.first
      scope.send(method, path)
    end

    def failure_message
      if redirect?
        "expected #{path.inspect} to route to #{expected.inspect}, but it was redirected to #{location.inspect}"
      else
        "expected #{path.inspect} to route to #{expected.inspect}, but it routes to #{path_params.inspect}"
      end
    end

    def failure_message_when_negated
      "expected #{path.inspect} not to route to #{expected.inspect}"
    end

    def description
      "route #{path.inspect} to #{expected.inspect}"
    end

    def params_match?
      expected.all? { |key, value| params[key] == value }
    end

    def path_params
      params.except(*URL_PARAMS)
    end
  end

  def route_to(*expected)
    RouteToMatcher.new(self, *expected)
  end

  class BeRoutableMatcher
    attr_reader :scope

    delegate :request, :response, to: :scope
    delegate :params, :path, to: :request
    delegate :location, :successful?, :redirect?, to: :response

    def initialize(scope)
      @scope = scope
    end

    def matches?(actual)
      process(actual) if Hash === actual
      successful? && !redirect?
    end

    def process(request)
      method, path = request.first
      scope.send(method, path)
    end

    def failure_message
      if redirect?
        "expected #{path.inspect} to be routable, but it was redirected to #{location.inspect}"
      else
        "expected #{path.inspect} to be routable"
      end
    end

    def failure_message_when_negated
      if redirect?
        "expected #{path.inspect} not to be routable, but it was redirected to #{location.inspect}"
      else
        "expected #{path.inspect} not to be routable, but it routes to #{path_params.inspect}"
      end
    end

    def description
      "be routable"
    end

    def path_params
      params.except(*URL_PARAMS)
    end
  end

  def be_routable
    BeRoutableMatcher.new(self)
  end

  class RedirectToMatcher
    attr_reader :scope, :location, :status

    delegate :request, :response, to: :scope
    delegate :params, :path, to: :request
    delegate :successful?, :redirect?, to: :response

    def initialize(scope, location, status)
      @scope, @location, @status = scope, location, status
    end

    def matches?(actual)
      process(actual) if Hash === actual
      redirect? && matches_location? && matches_status?
    end

    def matches_location?
      response.location == location
    end

    def matches_status?
      status.nil? || response.status == status
    end

    def process(request)
      method, path = request.first
      scope.send(method, path)
    end

    def expected_message
      "expected #{path.inspect} to redirect to #{location.inspect}"
    end

    def failure_message
      if redirect?
        "#{expected_message}, but it was redirected to #{response.location.inspect}"
      elsif successful?
        "#{expected_message}, but it was routed to #{path_params.inspect}"
      else
        "#{expected_message}, but it was not routable"
      end
    end

    def failure_message_when_negated
      "expected #{path.inspect} not to redirect to #{location.inspect}, but it was"
    end

    def description
      "redirect #{path.inspect} to #{location.inspect}"
    end

    def path_params
      params.except(*URL_PARAMS)
    end
  end

  def redirect_to(location, status = nil)
    RedirectToMatcher.new(self, location, status)
  end

  def permanently_redirect_to(location)
    RedirectToMatcher.new(self, location, 301)
  end

  def temporarily_redirect_to(url)
    RedirectToMatcher.new(self, location, 302)
  end
end

RSpec.configure do |config|
  config.include(RequestRoutingMatchers, type: :routes)
  config.include(RSpec::Rails::RequestExampleGroup, type: :routes)

  config.before(:each, type: :routes) do |example|
    if example.metadata[:admin]
      host! Site.moderate_host_with_port
    else
      host! Site.host_with_port
    end

    https!
  end

  config.around(:each, type: :routes) do |example|
    begin
      env_config = Rails.application.env_config
      show_exceptions = env_config['action_dispatch.show_exceptions']
      env_config['action_dispatch.show_exceptions'] = :all
      example.run
    ensure
      env_config['action_dispatch.show_exceptions'] = show_exceptions
    end
  end

  config.before(:each, type: :routes) do
    dispatcher = ActionDispatch::Routing::RouteSet::Dispatcher

    allow_any_instance_of(dispatcher).to receive(:dispatch).and_return(
      [200, {'Content-Type' => 'text/html'}, ["OK"]]
    )
  end
end
