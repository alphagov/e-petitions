class CreateDomainLogs < ActiveRecord::Migration
  def change
    create_table :domain_logs do |t|
      t.string   :name, null: false
      t.datetime :created_at, null: false
    end

    add_index :domain_logs, :name
    add_index :domain_logs, :created_at
  end
end
