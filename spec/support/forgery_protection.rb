RSpec.configure do |config|
  mod = Module.new do
    def with_forgery_protection(on_or_off, &block)
      begin
        current = ActionController::Base.allow_forgery_protection
        ActionController::Base.allow_forgery_protection = on_or_off
        yield
      ensure
        ActionController::Base.allow_forgery_protection = current
      end
    end
  end

  config.include(mod, type: :request)

  config.around(:each, type: :request) do |example|
    if example.metadata.key?(:csrf)
      with_forgery_protection(example.metadata[:csrf]) do
        example.run
      end
    else
      example.run
    end
  end
end
