RSpec.configure do |config|
  config.include(ActiveJob::TestHelper)

  config.before(:each) do
    ActiveJob::Base.queue_adapter.enqueued_jobs = []
    ActiveJob::Base.queue_adapter.performed_jobs = []
  end
end
