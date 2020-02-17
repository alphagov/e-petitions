class AddLocalizedFieldsToPetitions < ActiveRecord::Migration[5.2]

  class Petition < ActiveRecord::Base
  end

  def change
    :petitions.tap do |table|
      change_table table do |t|
        t.string :locale, limit: 7, null: false, default: "en-GB"
        t.string :action_en, limit: 255
        t.string :action_cy, limit: 255
        t.text :additional_details_en
        t.text :additional_details_cy
        t.string :background_en, limit: 500
        t.string :background_cy, limit: 500

        t.index "to_tsvector('english'::regconfig, (action_en)::text)",
          name: "index_#{table}_on_action_en",
          using: :gin
        t.index "to_tsvector('english'::regconfig, additional_details_en)",
          name: "index_#{table}_on_additional_details_en",
          using: :gin
        t.index "to_tsvector('english'::regconfig, (background_en)::text)",
          name: "index_#{table}_on_background_en",
          using: :gin

        t.index "to_tsvector('simple'::regconfig, (action_cy)::text)",
          name: "index_#{table}_on_action_cy",
          using: :gin
        t.index "to_tsvector('simple'::regconfig, additional_details_cy)",
          name: "index_#{table}_on_additional_details_cy",
          using: :gin
        t.index "to_tsvector('simple'::regconfig, (background_cy)::text)",
          name: "index_#{table}_on_background_cy",
          using: :gin
      end

      reversible do |dir|
        dir.up    { change_column_null table, :action, true }
        dir.down  { change_column_null table, :action, false }
      end
    end

    reversible do |dir|
      dir.up do
        Petition.tap do |klass|
          klass.reset_column_information
          klass.find_each do |p|
            p.update!(
              action_en:              p.action,
              additional_details_en:  p.additional_details,
              background_en:          p.background
            )
          end
        end
      end

      dir.down do
        Petition.tap do |klass|
          klass.reset_column_information
          klass.find_each do |p|
            p.update!(
              action:                 p.action_en              || p.action_cy,
              additional_details:     p.additional_details_en  || p.additional_details_cy,
              background:             p.background_en          || p.background_cy
            )
          end
        end
      end
    end
  end
end
