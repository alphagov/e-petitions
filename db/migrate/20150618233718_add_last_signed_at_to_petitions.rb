class AddLastSignedAtToPetitions < ActiveRecord::Migration
  def change
    change_table :petitions do |t|
      t.datetime :last_signed_at
      t.index :last_signed_at
    end
  end
end
