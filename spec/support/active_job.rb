RSpec.configure do |config|
  helpers = Module.new do
    def disable_test_adapter
      ActiveJob::Base.disable_test_adapter
    end

    def enable_test_adapter
      ActiveJob::Base.enable_test_adapter(queue_adapter_for_test)
    end

    def without_test_adapter(&block)
      disable_test_adapter
      yield
    ensure
      enable_test_adapter
    end
  end

  config.include(ActiveJob::TestHelper)
  config.include(helpers)
end
