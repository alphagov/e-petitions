class MigrateArchivedSignatureIndexesToPartialIndexes < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:archived_signatures, name: "index_archived_signatures_on_petition_id_where_creator_is_true")
      add_index :archived_signatures, :petition_id,
        where: "creator = 't'",  unique: true, algorithm: :concurrently,
        name: "index_archived_signatures_on_petition_id_where_creator_is_true"
    end

    unless index_exists?(:archived_signatures, name: "index_archived_signatures_on_petition_id_where_sponsor_is_true")
      add_index :archived_signatures, :petition_id,
        where: "sponsor = 't'", algorithm: :concurrently,
        name: "index_archived_signatures_on_petition_id_where_sponsor_is_true"
    end

    if index_exists?(:archived_signatures, [:creator, :petition_id])
      remove_index :archived_signatures, [:creator, :petition_id]
    end

    if index_exists?(:archived_signatures, [:sponsor, :petition_id])
      remove_index :archived_signatures, [:sponsor, :petition_id]
    end
  end

  def down
    if index_exists?(:archived_signatures, name: "index_archived_signatures_on_petition_id_where_creator_is_true")
      remove_index :archived_signatures, name: "index_archived_signatures_on_petition_id_where_creator_is_true"
    end

    if index_exists?(:archived_signatures, name: "index_archived_signatures_on_petition_id_where_sponsor_is_true")
      remove_index :archived_signatures, name: "index_archived_signatures_on_petition_id_where_sponsor_is_true"
    end

    unless index_exists?(:archived_signatures, [:creator, :petition_id])
      add_index :archived_signatures, [:creator, :petition_id]
    end

    unless index_exists?(:archived_signatures, [:sponsor, :petition_id])
      add_index :archived_signatures, [:sponsor, :petition_id]
    end
  end

  private

  def index_exists?(table, names_or_options)
    if names_or_options.is_a?(Hash)
      select_value("SELECT to_regclass('#{names_or_options[:name]}')")
    else
      select_value("SELECT to_regclass('index_#{table}_on_#{Array(names_or_options).join('_and_')}')")
    end
  end
end
