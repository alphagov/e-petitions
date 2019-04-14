class AddFormTokenToSignatures < ActiveRecord::Migration
  def up
    unless column_exists?(:signatures, :form_token)
      add_column :signatures, :form_token, :string
    end
  end

  def down
    if column_exists?(:signatures, :form_token)
      remove_column :signatures, :form_token
    end
  end
end
