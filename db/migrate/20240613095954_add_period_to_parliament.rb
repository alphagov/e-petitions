class AddPeriodToParliament < ActiveRecord::Migration[7.1]
  def change
    period_sql = <<-SQL
      CASE
        WHEN opening_at IS NULL THEN date_part('year', created_at) || '-'
        WHEN dissolution_at IS NULL THEN date_part('year', opening_at) || '-'
        ELSE (date_part('year', opening_at) || '-' || date_part('year', dissolution_at))
      END
    SQL

    add_column :parliaments, :period, :virtual, type: :string, as: period_sql, stored: true
  end
end
