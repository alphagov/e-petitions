class AddPeriodToParliament < ActiveRecord::Migration[7.1]
  def change
    add_column :parliaments, :period, :string

    execute <<-SQL
    UPDATE parliaments
    SET period = 
    (CASE
    WHEN opening_at IS NULL THEN EXTRACT(year FROM now()) || '-'
    WHEN dissolution_at IS NULL THEN EXTRACT(year FROM opening_at) || '-'
    ELSE EXTRACT(year FROM opening_at) || '-' || EXTRACT(year FROM dissolution_at)
    END)
    SQL
  end
end
