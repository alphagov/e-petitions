require 'active_job/logging'

# TODO: remove this when the following issue is resolved:
#       https://github.com/rails/rails/issues/21036

# Unsubscribe all Active Job notifications
ActiveSupport::Notifications.unsubscribe 'perform_start.active_job'
ActiveSupport::Notifications.unsubscribe 'perform.active_job'
ActiveSupport::Notifications.unsubscribe 'enqueue_at.active_job'
ActiveSupport::Notifications.unsubscribe 'enqueue.active_job'

module ActiveJob
  module Logging
    class LogSubscriber
      # Remove all public methods so that we can use the class
      # as the base class for our two new subscriber classes.
      remove_method :enqueue
      remove_method :enqueue_at
      remove_method :perform_start
      remove_method :perform
    end

    class EnqueueSubscriber < LogSubscriber
      def enqueue(event)
        info do
          job = event.payload[:job]
          "Enqueued #{job.class.name} (Job ID: #{job.job_id}) to #{queue_name(event)}" + args_info(job)
        end
      end

      def enqueue_at(event)
        info do
          job = event.payload[:job]
          "Enqueued #{job.class.name} (Job ID: #{job.job_id}) to #{queue_name(event)} at #{scheduled_at(event)}" + args_info(job)
        end
      end
    end

    class ExecutionSubscriber < LogSubscriber
      def perform_start(event)
        info do
          job = event.payload[:job]
          "Performing #{job.class.name} from #{queue_name(event)}" + args_info(job)
        end
      end

      def perform(event)
        info do
          job = event.payload[:job]
          "Performed #{job.class.name} from #{queue_name(event)} in #{event.duration.round(2)}ms"
        end
      end
    end
  end
end

# Suubscribe to Active Job notifications
ActiveJob::Logging::EnqueueSubscriber.attach_to :active_job
ActiveJob::Logging::ExecutionSubscriber.attach_to :active_job
