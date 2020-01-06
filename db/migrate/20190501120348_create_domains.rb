class CreateDomains < ActiveRecord::Migration[4.2]
  def change
    create_table :domains do |t|
      t.belongs_to :canonical_domain, index: true
      t.string     :name, limit: 100, null: false
      t.string     :strip_characters, limit: 10
      t.string     :strip_extension, limit: 10, default: "+"
      t.timestamps null: false
    end

    add_index :domains, :name, unique: true
    add_foreign_key :domains, :domains, column: :canonical_domain_id
  end
end
