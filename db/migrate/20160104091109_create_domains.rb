class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string   :name, null: false
      t.integer  :current_rate, default: 0, null: false
      t.integer  :maximum_rate, default: 0, null: false
      t.datetime :resolved_at, default: nil
      t.string   :state, default: nil

      t.timestamps null: false
    end

    add_index :domains, :name, unique: true
    add_index :domains, :current_rate
    add_index :domains, :resolved_at
    add_index :domains, :state
  end
end
