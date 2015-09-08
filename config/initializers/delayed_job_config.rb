Delayed::Worker.max_attempts = 15
Delayed::Worker.max_run_time = 6.hours

require 'active_job/queue_adapters/delayed_job_adapter'

# We patch in the display_name method to the Delayed Job queue adapter
# so that all the jobs aren't aggregated under one name in AppSignal.
module ActiveJob
  module QueueAdapters
    class DelayedJobAdapter
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

# Override the default after_fork method on Delayed::Backend::ActiveRecord::Job
# to restart the Appsignal agent when the worker is forked.
module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        def self.after_fork
          # Worker specific setup for Rails 4.1+
          # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
          ::ActiveRecord::Base.establish_connection

          # Let AppSignal know that a worker process has been forked
          ::Appsignal.agent.forked! if defined?(::Appsignal) && ::Appsignal.config.active?
        end
      end
    end
  end
end
