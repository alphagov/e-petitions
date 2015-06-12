class AddValidatedAtToSignatures < ActiveRecord::Migration
  def change
    change_table :signatures do |t|
      t.datetime :validated_at
      t.index :validated_at
    end
  end
end
