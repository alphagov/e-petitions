Delayed::Worker.max_attempts = 15
Delayed::Worker.max_run_time = 6.hours
Delayed::Worker.default_priority = 100

require 'active_job/queue_adapters/delayed_job_adapter'

# Add a before_save callback to set the priority based on the queue name
module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        QUEUE_PRIORITIES = {
          "highest_priority" => 0,
          "high_priority"    => 10,
          "low_priority"     => 50
        }

        QUEUE_PRIORITIES.default = 25

        before_create do
          self.priority = QUEUE_PRIORITIES[queue]
        end
      end
    end
  end
end
