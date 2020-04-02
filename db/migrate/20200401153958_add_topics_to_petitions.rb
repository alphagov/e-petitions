class AddTopicsToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class Petition < ActiveRecord::Base; end
  class ArchivedPetition < ActiveRecord::Base; end

  def up
    unless column_exists?(:petitions, :topics)
      add_column :petitions, :topics, :integer, array: true
      change_column_default :petitions, :topics, []

      Petition.find_each { |p| p.update_columns(topics: []) }

      change_column_null :petitions, :topics, false

      add_index :petitions, :topics, using: :gin, opclass: :gin__int_ops, algorithm: :concurrently
    end

    unless column_exists?(:archived_petitions, :topics)
      add_column :archived_petitions, :topics, :integer, array: true
      change_column_default :archived_petitions, :topics, []

      ArchivedPetition.find_each { |p| p.update_columns(topics: []) }

      change_column_null :archived_petitions, :topics, false
      add_index :archived_petitions, :topics, using: :gin, opclass: :gin__int_ops, algorithm: :concurrently
    end
  end

  def down
    if column_exists?(:petitions, :topics)
      remove_column :petitions, :topics
    end

    if column_exists?(:archived_petitions, :topics)
      remove_column :archived_petitions, :topics
    end
  end
end
