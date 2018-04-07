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
    class EnqueueSubscriber < LogSubscriber
      define_method :enqueue, instance_method(:enqueue)
      define_method :enqueue_at, instance_method(:enqueue_at)
    end

    class ExecutionSubscriber < LogSubscriber
      define_method :perform_start, instance_method(:perform_start)
      define_method :perform, instance_method(:perform)
    end
  end
end

# Subscribe to Active Job notifications
ActiveJob::Logging::EnqueueSubscriber.attach_to :active_job
ActiveJob::Logging::ExecutionSubscriber.attach_to :active_job
