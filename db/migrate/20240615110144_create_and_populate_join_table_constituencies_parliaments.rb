class CreateAndPopulateJoinTableConstituenciesParliaments < ActiveRecord::Migration[7.1]
  def change
    create_join_table :constituencies, :parliaments do |t|
      t.string :constituency_external_id
      t.timestamps
    end
  end
end
