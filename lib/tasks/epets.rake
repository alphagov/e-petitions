require 'csv'

namespace :epets do
  desc "Add sysadmin user"
  task :add_sysadmin_user => :environment do
    if AdminUser.find_by(email: 'admin@example.com').nil?
       admin = AdminUser.new(:first_name => 'Cool', :last_name => 'Admin', :email => 'admin@example.com')
       admin.role = 'sysadmin'
       admin.save!
     end
  end

  desc "Email threshold users with a list of threshold petitions"
  task :threshold_email_reminder => :environment do
    Task.run("epets:threshold_email_reminder") do
      EmailThresholdReminderJob.perform_later
    end
  end

  desc "Special resend of signature email validation"
  task :special_resend_of_signature_email_validation => :environment do
    EmailReminder.special_resend_of_signature_email_validation
  end

  namespace :whenever do
    desc "Update the Primary Server crontab"
    task :update_crontab_primary => :environment do
      Whenever::CommandLine.execute(
        :update => true,
        :set => "environment=#{RAILS_ENV}",
        :identifier => 'Epets_primary_server'
      )
    end

    desc "Update the all servers crontab"
    task :update_crontab_all => :environment do
      Whenever::CommandLine.execute(
        :update => true,
        :set => "environment=#{RAILS_ENV}",
        :identifier => 'Epets_all_servers',
        :file => 'config/schedule_all_servers.rb'
      )
    end
  end

  namespace :jobs do
    desc "Unlock all delayed jobs (to be used after a restart)"
    task :unlock_all => :environment do
      Delayed::Job.update_all("locked_by = NULL, locked_at = NULL")
    end
  end

  namespace :site do
    desc "Enable the website"
    task :enable => :environment do
      Site.instance.update! enabled: true
    end

    desc "Disable the website"
    task :disable => :environment do
      Site.instance.update! enabled: false
    end

    desc "Protect the website"
    task :protect => :environment do
      Site.instance.update! protected: true, username: ENV.fetch('SITE_USERNAME'), password: ENV.fetch('SITE_PASSWORD')
    end

    desc "Unprotect the website"
    task :unprotect => :environment do
      Site.instance.update! protected: false
    end

    desc "Start the signature count updater if it's not running"
    task :signature_counts => :environment do
      Task.run("epets:site:signature_counts", 10.minutes) do
        break unless Site.update_signature_counts

        unless Site.signature_count_updated_at > 15.minutes.ago
          UpdateSignatureCountsJob.perform_later
        end
      end
    end

    desc "Track trending domains"
    task :trending_domains => :environment do
      Task.run("epets:site:trending_domains", 30.minutes) do
        TrendingDomainsByPetitionJob.perform_later
      end
    end

    desc "Track trending IP addresses"
    task :trending_ips => :environment do
      Task.run("epets:site:trending_ips", 30.minutes) do
        TrendingIpsByPetitionJob.perform_later
      end
    end
  end

  namespace :cache do
    desc "Clear the cache"
    task :clear => :environment do
      Rails.cache.clear
    end
  end

  namespace :countries do
    desc "Load country data"
    task load: :environment do
      location = Class.new(ActiveRecord::Base) { self.table_name = "locations" }
      file = Rails.root.join("data", "countries.csv")

      CSV.foreach(file, headers: true).each do |row|
        location.create!(row.to_h)
      end
    end

    task delete: :environment do
      location = Class.new(ActiveRecord::Base) { self.table_name = "locations" }
      location.delete_all
    end

    task reset: ["epets:countries:delete", "epets:countries:load"]
  end
end
