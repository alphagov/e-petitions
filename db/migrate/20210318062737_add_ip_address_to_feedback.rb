class AddIpAddressToFeedback < ActiveRecord::Migration[5.2]
  def change
    add_column :feedback, :ip_address, :string, limit: 20
  end
end
