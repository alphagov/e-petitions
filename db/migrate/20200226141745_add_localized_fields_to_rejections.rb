class AddLocalizedFieldsToRejections < ActiveRecord::Migration[5.2]

  class Rejection < ActiveRecord::Base
  end

  def change
    change_table :rejections do |t|
      t.text :details_en
      t.text :details_cy
    end

    reversible do |dir|
      dir.up do
        Rejection.reset_column_information
        Rejection.find_each do |r|
          r.update!(details_en: r.details)
        end
      end

      dir.down do
        Rejection.reset_column_information
        Rejection.find_each do |r|
          r.update!(details: r.details_en || r.details_cy)
        end
      end
    end
  end
end
