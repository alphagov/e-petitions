class CreateTrendingIps < ActiveRecord::Migration[4.2]
  def change
    create_table :trending_ips do |t|
      t.belongs_to :petition, index: true, foreign_key: true
      t.inet :ip_address, null: false
      t.string :country_code, limit: 30, null: false
      t.integer :count, null: false
      t.datetime :starts_at, null: false
      t.timestamps null: false
    end

    add_index :trending_ips, [:created_at, :count], order: { starts_at: :desc, count: :desc }
    add_index :trending_ips, [:ip_address, :petition_id]
  end
end
