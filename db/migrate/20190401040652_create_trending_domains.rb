class CreateTrendingDomains < ActiveRecord::Migration[4.2]
  def change
    create_table :trending_domains do |t|
      t.belongs_to :petition, index: true, foreign_key: true
      t.string :domain, limit: 100, null: false
      t.integer :count, null: false
      t.datetime :starts_at, null: false
      t.timestamps null: false
    end

    add_index :trending_domains, [:created_at, :count], order: { starts_at: :desc, count: :desc }
    add_index :trending_domains, [:domain, :petition_id]
  end
end
