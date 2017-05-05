namespace :epets do
  namespace :signatures do
    desc "Backfill signature UUIDs"
    task :backfill_uuids => :environment do
      signature = Signature.where(uuid: nil).first

      if signature
        BackfillSignatureUuidsJob.perform_later(signature.id)
      end
    end
  end
end
