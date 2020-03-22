class AddLocaleToSignatures < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class Signature < ActiveRecord::Base; end

  def up
    add_column :signatures, :locale, :string, limit: 10

    Signature.find_each do |signature|
      if signature.email =~ /cymru\z/
        signature.update!(locale: "cy-GB")
      else
        signature.update!(locale: "en-GB")
      end
    end

    change_column_default :signatures, :locale, "en-GB"
    change_column_null :signatures, :locale, false
  end

  def down
    remove_column :signatures, :locale
  end
end
