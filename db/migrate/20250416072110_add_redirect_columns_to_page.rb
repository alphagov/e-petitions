class AddRedirectColumnsToPage < ActiveRecord::Migration[7.2]
  def change
    add_column :pages, :enabled, :boolean
    add_column :pages, :redirect, :boolean
    add_column :pages, :redirect_url, :string

    up_only do
      execute <<~SQL
        UPDATE pages SET enabled = 't', redirect = 'f'
      SQL

      change_column_null :pages, :enabled, false
      change_column_null :pages, :redirect, false

      change_column_default :pages, :enabled, true
      change_column_default :pages, :redirect, false
    end
  end
end
