class ChangePeriodToUseStateOpeningAt < ActiveRecord::Migration[7.2]
  def up
    period_sql = <<-SQL
      CASE
        WHEN state_opening_at IS NULL THEN date_part('year', created_at) || '-'
        WHEN dissolution_at IS NULL THEN date_part('year', state_opening_at) || '-'
        ELSE (date_part('year', state_opening_at) || '-' || date_part('year', dissolution_at))
      END
    SQL

    remove_column :parliaments, :period
    add_column :parliaments, :period, :virtual, type: :string, as: period_sql, stored: true
  end

  def down
    period_sql = <<-SQL
      CASE
        WHEN opening_at IS NULL THEN date_part('year', created_at) || '-'
        WHEN dissolution_at IS NULL THEN date_part('year', opening_at) || '-'
        ELSE (date_part('year', opening_at) || '-' || date_part('year', dissolution_at))
      END
    SQL

    remove_column :parliaments, :period
    add_column :parliaments, :period, :virtual, type: :string, as: period_sql, stored: true
  end
end
