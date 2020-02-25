class AddReferredAtToPetitions < ActiveRecord::Migration[5.2]
  def change
    add_column :petitions, :referred_at, :datetime
    add_index :petitions, [:referred_at, :created_at], order: { referred_at: :asc, created_at: :desc }
  end
end
