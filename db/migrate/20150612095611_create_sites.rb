class CreateSites < ActiveRecord::Migration[4.2]
  def change
    create_table :sites do |t|
      t.string    :title, limit: 50, null: false, default: 'Petition parliament'
      t.string    :url, limit: 50, null: false, default: 'https://petition.parliament.uk'
      t.string    :email_from, limit: 50, null: false, default: 'no-reply@petition.parliament.uk'
      t.string    :username, limit: 30
      t.string    :password_digest, limit: 60
      t.boolean   :enabled, null: false, default: true
      t.boolean   :protected, null: false, default: false
      t.integer   :petition_duration, null: false, default: 6
      t.integer   :minimum_number_of_sponsors, null: false, default: 5
      t.integer   :maximum_number_of_sponsors, null: false, default: 20
      t.integer   :threshold_for_moderation, null: false, default: 5
      t.integer   :threshold_for_response, null: false, default: 10000
      t.integer   :threshold_for_debate, null: false, default: 100000
      t.datetime  :last_checked_at
      t.timestamps null: false
    end
  end
end
