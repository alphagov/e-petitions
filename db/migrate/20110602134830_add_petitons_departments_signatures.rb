class AddPetitonsDepartmentsSignatures < ActiveRecord::Migration
  def self.up
    create_table :departments, :force => true do |t|
      t.string   :name, :null => false
      t.string   :description
      t.timestamps
    end
    add_index :departments, [:name], :unique => true
    
    create_table :petitions, :force => true do |t|
      t.string   :title, :null => false
      t.string   :description
      t.string   :response
      t.string   :state, :null => false, :default => 'pending', :limit => 10
      t.datetime :open_at
      t.integer  :department_id, :null => false
      t.integer  :creator_signature_id
      t.timestamps
    end
    add_index :petitions, [:department_id, :state, :created_at]
    add_index :petitions, [:state]
    add_index :petitions, [:creator_signature_id], :unique => true
    
    create_table :signatures, :force => true do |t|
      t.string   :name, :null => false
      t.string   :email, :null => false
      t.string   :state, :null => false, :default => 'pending', :limit => 10
      t.integer  :perishable_token
      t.string   :address
      t.string   :town
      t.string   :postcode
      t.string   :country
      t.string   :ip_address, :limit => 20
      t.integer  :petition_id, :null => false
      t.timestamps
    end
    add_index :signatures, [:petition_id, :state, :name]
    add_index :signatures, [:email, :petition_id], :unique => true
  end

  def self.down
    drop_table :departments
    drop_table :petitions
    drop_table :signatures
  end
end
