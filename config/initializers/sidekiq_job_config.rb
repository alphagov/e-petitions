# Delayed::Worker.max_attempts = 15
# Delayed::Worker.max_run_time = 6.hours

require 'active_job/queue_adapters/sidekiq_adapter'

# We patch in the display_name method to the Delayed Job queue adapter
# so that all the jobs aren't aggregated under one name in AppSignal.
module ActiveJob
  module QueueAdapters
    class SidekiqAdapter
      class JobWrapper
        def display_name
          if job_data['job_class'] == 'ActionMailer::DeliveryJob'
            "#{job_data['arguments'][0]}##{job_data['arguments'][1]}"
          else
            "#{job_data['job_class']}#perform"
          end
        end
      end
    end
  end
end
