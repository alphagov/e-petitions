class AddValidatedFromToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :validated_ip, :string
  end
end
