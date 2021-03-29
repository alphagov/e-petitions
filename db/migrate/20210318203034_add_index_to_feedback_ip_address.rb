class AddIndexToFeedbackIpAddress < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :feedback, :ip_address, algorithm: :concurrently
  end
end
