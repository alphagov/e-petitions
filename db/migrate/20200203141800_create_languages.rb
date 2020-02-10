class CreateLanguages < ActiveRecord::Migration[5.2]
  class Language < ActiveRecord::Base; end

  def change
    create_table :languages do |t|
      t.string :locale, limit: 10, null: false, index: { unique: true }
      t.string :name, limit: 30, null: false, index: { unique: true }
      t.jsonb :translations, null: false, default: {}
      t.timestamps
    end

    up_only do
      Language.create!(name: "English", locale: "en-GB")
      Language.create!(name: "Welsh", locale: "cy-GB")
    end
  end
end
