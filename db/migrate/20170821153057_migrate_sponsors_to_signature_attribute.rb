class MigrateSponsorsToSignatureAttribute < ActiveRecord::Migration[4.2]
  class Sponsor < ActiveRecord::Base; end
  class Signature < ActiveRecord::Base; end

  def up
    add_column :signatures, :sponsor, :boolean, null: false, default: false

    # Migrate any data (should be dev environment only)
    sponsors = Sponsor.pluck(:signature_id)
    Signature.where(id: sponsors).update_all(sponsor: true)

    remove_foreign_key :sponsors, :petitions
    remove_foreign_key :sponsors, :signatures
    drop_table :sponsors
  end

  def down
    create_table :sponsors do |t|
      t.integer  :petition_id
      t.integer  :signature_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_foreign_key :sponsors, :petitions, on_delete: :cascade
    add_foreign_key :sponsors, :signatures, on_delete: :cascade

    # Migrate any data (should be dev environment only)
    signatures = Signature.where(sponsor: true).pluck(:id, :petition_id)
    signatures.each do |signature_id, petition_id|
      Sponsor.create!(signature_id: signature_id, petition_id: petition_id)
    end

    remove_column :signatures, :sponsor
  end
end
