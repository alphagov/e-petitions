RSpec.configure do |config|
  config.around(:each, type: :request) do |example|
    OmniAuth.config.test_mode = true
    existing_failure_proc = OmniAuth.config.on_failure

    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }

    example.run
  ensure
    OmniAuth.config.mock_auth[:example] = nil
    OmniAuth.config.on_failure = existing_failure_proc
    OmniAuth.config.test_mode = false
  end
end
