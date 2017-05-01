namespace :epets do
  namespace :signatures do
    desc "Backfill signature UUIDs"
    task :backfill_uuids => :environment do
      BackfillSignatureUuidsJob.perform_later
    end
  end
end
