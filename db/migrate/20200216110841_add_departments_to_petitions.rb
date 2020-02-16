class AddDepartmentsToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class Petition < ActiveRecord::Base; end
  class ArchivedPetition < ActiveRecord::Base; end

  def up
    add_column :petitions, :departments, :integer, array: true
    add_column :archived_petitions, :departments, :integer, array: true

    Petition.find_each { |p| p.update!(departments: []) }
    ArchivedPetition.find_each { |p| p.update!(departments: []) }

    change_column_default :petitions, :departments, []
    change_column_default :archived_petitions, :departments, []

    change_column_null :petitions, :departments, false
    change_column_null :archived_petitions, :departments, false

    add_index :petitions, :departments, using: :gin, opclass: :gin__int_ops, algorithm: :concurrently
    add_index :archived_petitions, :departments, using: :gin, opclass: :gin__int_ops, algorithm: :concurrently
  end

  def down
    remove_column :petitions, :departments
    remove_column :archived_petitions, :departments
  end
end
