RSpec.configure do |config|
  config.around(immediate_delayed_job_work_off: true) do |example|
    old_dj = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false
    example.run
    Delayed::Worker.delay_jobs = old_dj
  end
end
