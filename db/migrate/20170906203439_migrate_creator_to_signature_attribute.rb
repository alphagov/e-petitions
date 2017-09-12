class MigrateCreatorToSignatureAttribute < ActiveRecord::Migration
  class Petition < ActiveRecord::Base; end
  class Signature < ActiveRecord::Base; end

  def up
    add_column :signatures, :creator, :boolean, null: false, default: false

    # Migrate any data (should be dev environment only)
    signatures = Petition.pluck(:creator_signature_id)
    Signature.where(id: signatures).update_all(creator: true)

    add_index :signatures, :petition_id, where: "creator = 't'", unique: true, name: "index_signatures_on_petition_id_where_creator_is_true"
    remove_foreign_key :petitions, column: :creator_signature_id
    remove_index :petitions, :creator_signature_id
    remove_column :petitions, :creator_signature_id
  end

  def down
    add_column :petitions, :creator_signature_id, :integer
    add_index :petitions, :creator_signature_id, unique: true
    add_foreign_key :petitions, :signatures, column: :creator_signature_id, on_delete: :restrict

    # Migrate any data (should be dev environment only)
    signatures = Signature.where(creator: true).pluck(:id, :petition_id)
    signatures.each do |signature_id, petition_id|
      Petition.where(id: petition_id).update_all(creator_signature_id: signature_id)
    end

    change_column_null :petitions, :creator_signature_id, false
    change_column_default :petitions, :creator_signature_id, nil
    remove_index :signatures, name: "index_archived_signatures_on_petition_id_where_creator_is_true"
    remove_column :signatures, :creator
  end
end
