require 'app_config'

namespace :epets do

  desc 'Add sysadmin user'
  task :add_sysadmin_user => :environment do
    if AdminUser.find_by(email: 'admin@example.com').nil?
       admin = AdminUser.new(:first_name => 'Cool', :last_name => 'Admin', :email => 'admin@example.com')
       admin.role = 'sysadmin'
       admin.password = admin.password_confirmation = 'Letmein1!'
       admin.save!
     end
  end

  desc "Flushes memcached"
  task :flush_memcached => :environment do
    Rails.cache.clear
  end

  desc 'Wait for sunspot server to start.'
  task :wait_for_sunspot_to_start => :environment do
    require 'lib/sunspot_server_util'
    port = ENV['port']
    if port.blank? then
      puts 'Specify a port number (port={port number})'
    else
      SunspotServerUtil.wait_for_sunspot_to_start(port)
    end
  end

  desc "Email admin users with a list of validated petitions"
  task :admin_email_reminder => :environment do
    EmailReminder.admin_email_reminder
  end

  desc "Email threshold users with a list of threshold petitions"
  task :threshold_email_reminder => :environment do
    EmailReminder.threshold_email_reminder
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

  desc "Writes out the json data"
  task :write_json_data => :environment do
    renderer = JsonRenderer.new
    renderer.render_all_petitions
    renderer.render_individual_over_threshold_petitions
  end

  def self.each_signature(to_encrypt)
    count = to_encrypt.count
    puts "Started #{Time.now} - #{count} records to process"
    to_encrypt.find_each do |signature|
      yield signature
      count -= 1
      puts "#{count} to go" if (count % 1000 == 0)
    end
    puts "Ended #{Time.now}"
  end

  desc "Add encrypt emails to new email"
  task :encrypt_email => :environment do
    class EncryptedSignature < ActiveRecord::Base
      class EmailDowncaser
        def self.dump(value); value.downcase; end
        def self.load(value); value; end
      end
      attr_encrypted :email, :key => AppConfig.email_encryption_key, :attribute => "encrypted_email", :marshal => true, :marshaler => EmailDowncaser
    end

    puts "Encrypting..."

    EncryptedSignature.record_timestamps = false
    each_signature(EncryptedSignature.where("encrypted_email IS NULL")) do |encrypted_signature|
      encrypted_signature.update_attribute(:email, Signature.find(encrypted_signature.id).email);
    end
  end

  desc "Synchronize signatures table"
  task :sync_new_signatures_table => :environment do
    puts "Syncing signatures table"
    last_sync_time = ActiveRecord::Base.connection.execute("SELECT MAX(updated_at) from encrypted_signatures").fetch_row.first

    if (last_sync_time)
      puts "Removing records changed since #{last_sync_time}"
      each_signature(Signature.where(%(updated_at >= "#{last_sync_time}"))) do |signature|
        ActiveRecord::Base.connection.execute("DELETE FROM encrypted_signatures WHERE id=#{signature.id}")
      end
    else
      puts "Not synced before"
    end

    fields = 'name,created_at,postcode,last_emailed_at,country,updated_at,perishable_token,id,petition_id,state,notify_by_email,ip_address'

    puts "Inserting missing records"
    while((todo_count = Signature.count - EncryptedSignature.count) > 0)
      puts "Syncing: #{todo_count} to do"
      ActiveRecord::Base.connection.execute %{
        INSERT INTO encrypted_signatures (#{fields})
        SELECT #{fields} FROM signatures
        WHERE NOT EXISTS(SELECT 1 FROM encrypted_signatures WHERE encrypted_signatures.id = signatures.id) LIMIT 10000;
      }
    end
    puts "Done"
  end

  desc "Update all Petitions due to finish after dissolution of Parliament to the fixed closing date"
  task :update_petition_closing_dates => :environment do
    puts 'Finding affected petitions'
    affected_petitions = Petition.where("closed_at > ? AND state = ?", Petition::FIXED_CLOSING_DATE, 'open')
    puts 'Updating closing dates'
    affected_petitions.each do |petition|
      petition.closed_at = Petition::FIXED_CLOSING_DATE
      petition.save!
    end
    puts 'Done'
  end

  desc "Send notification email to all creators of petitions that are effected by changes"
  task :send_closing_date_notification_emails => :environment do
    puts 'Finding affected petitions'
    affected_petitions = Petition.where("closed_at > ? AND state = ?", Petition::FIXED_CLOSING_DATE, 'open')
    puts 'Sending emails'
    affected_petitions.each do |petition|
      PetitionMailer.notify_creator_of_closing_date_change(petition.creator_signature).deliver
    end
    puts 'Done'
  end
end

