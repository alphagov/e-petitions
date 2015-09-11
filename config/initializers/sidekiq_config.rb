Sidekiq.configure_server do |config|
  # runs after your app has finished initializing but before any jobs are dispatched.
  config.on(:startup) do
    # Restart the AppSignal thread that we stopped in the initializer
    Appsignal.agent.start_thread if defined?(Appsignal) && Appsignal.config.active?
  end
end

Sidekiq.default_worker_options = { "retry" => 15, "backtrace" => true }

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
