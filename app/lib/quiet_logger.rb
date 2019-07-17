class QuietLogger
  attr_reader :app, :options, :paths

  def initialize(app, options = {})
    @app = app
    @options = options
    @paths = Array(options[:paths])
  end

  def call(env)
    if silence_request?(env)
      logger.silence { app.call(env) }
    else
      app.call(env)
    end
  end

  private

    def silence_request?(env)
      paths.any? { |path| path === env['PATH_INFO'] }
    end

    def logger
      Rails.logger
    end
end
