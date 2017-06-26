class CreateFeedback < ActiveRecord::Migration[4.2]
  def change
    create_table :feedback do |t|
      t.string :comment, limit: 32768, null: false
      t.string :petition_link_or_title
      t.string :email
      t.string :user_agent
    end
  end
end
