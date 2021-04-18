class IncreaseFeedbackIpAddressSize < ActiveRecord::Migration[6.1]
  def up
    change_column(:feedback, :ip_address, :string, limit: 40)
  end

  def down
    change_column(:feedback, :ip_address, :string, limit: 20)
  end
end
