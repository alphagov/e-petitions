class CreateDissolutionNotification < ActiveRecord::Migration[4.2]
  def change
    create_table :dissolution_notifications, id: false do |t|
      t.primary_key :id, :uuid, null: false, default: nil
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
