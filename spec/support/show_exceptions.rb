module ShowExceptionsHelper
  def with_show_exceptions(on_or_off, &block)
    begin
      env_config = Rails.application.env_config
      show_exceptions = env_config['action_dispatch.show_exceptions']
      env_config['action_dispatch.show_exceptions'] = on_or_off ? :all : :none

      yield
    ensure
      env_config['action_dispatch.show_exceptions'] = show_exceptions
    end
  end
end

RSpec.configure do |config|
  config.include(ShowExceptionsHelper, type: :request)

  config.around(:each, type: :request) do |example|
    if example.metadata.key?(:show_exceptions)
      with_show_exceptions(example.metadata[:show_exceptions]) do
        example.run
      end
    else
      example.run
    end
  end
end
