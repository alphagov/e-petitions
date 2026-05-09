class AddDisableTocToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :disable_toc, :boolean

    up_only do
      execute <<~SQL
        UPDATE pages SET disable_toc = false
      SQL

      change_column_null :pages, :disable_toc, false
      change_column_default :pages, :disable_toc, false
    end
  end
end
