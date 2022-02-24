namespace :epets do
  namespace :petitions do
    desc "Add a task to the queue to anonymize petitions at midnight"
    task :anonymize => :environment do
      Task.run("epets:petitions:anonymize") do
        time = Date.tomorrow.beginning_of_day
        AnonymizePetitionsJob.set(wait_until: time).perform_later(time.iso8601)
        Archived::AnonymizePetitionsJob.set(wait_until: time).perform_later(time.iso8601)
      end
    end

    desc "Add a task to the queue to close petitions at midnight"
    task :close => :environment do
      Task.run("epets:petitions:close") do
        time = Date.tomorrow.beginning_of_day
        ClosePetitionsJob.set(wait_until: time).perform_later(time.iso8601)
      end
    end

    desc "Add a task to the queue to validate petition counts"
    task :count => :environment do
      Task.run("epets:petitions:count") do
        PetitionCountJob.perform_later
      end
    end

    desc "Add a task to the queue to mark petitions as debated at midnight"
    task :debated => :environment do
      Task.run("epets:petitions:debated") do
        date = Date.tomorrow
        DebatedPetitionsJob.set(wait_until: date.beginning_of_day).perform_later(date.iso8601)
      end
    end

    desc "Add a task to the queue to extend petition deadlines at midnight"
    task :extend_deadline => :environment do
      Task.run("epets:petitions:extend_deadline") do
        ExtendPetitionDeadlinesJob.set(wait_until: Date.tomorrow.beginning_of_day).perform_later
      end
    end

    desc "Add a task to the queue to update petition statistics"
    task :update_statistics => :environment do
      Task.run("epets:petitions:update_statistics", 12.hours) do
        EnqueuePetitionStatisticsUpdatesJob.perform_later(24.hours.ago.iso8601)
      end
    end

    desc "Backfill moderation lag"
    task :backfill_moderation_lag => :environment do
      %w[petitions archived_petitions].each do |table_name|
        klass = Class.new(ActiveRecord::Base) do
          self.table_name = table_name

          def self.default_scope
            where(moderation_lag: nil).where.not(moderation_threshold_reached_at: nil)
          end

          def moderated?
            if respond_to?(:open_at)
              open_at? || rejected_at?
            else
              opened_at? || rejected_at?
            end
          end

          def moderated_at
            if respond_to?(:open_at)
              [open_at, rejected_at].compact.min
            else
              [opened_at, rejected_at].compact.min
            end
          end

          def moderation_lag
            moderated_at.to_date - moderation_threshold_reached_at.to_date
          end

          def update_moderation_lag
            update_column(:moderation_lag, moderation_lag)
          end
        end

        klass.find_each do |petition|
          next unless petition.moderated?

          petition.update_column(:moderation_lag, petition.moderation_lag)
        end
      end
    end

    desc "Email updated privacy policy"
    task :email_privacy_policy_updates, [:date] => :environment do |_task, args|
      time = (args.time || "2021-03-01").in_time_zone
      EmailPrivacyPolicyUpdatesJob.perform_now(time: time)
    end
  end
end
