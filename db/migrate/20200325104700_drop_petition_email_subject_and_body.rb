class DropPetitionEmailSubjectAndBody < ActiveRecord::Migration[5.2]
  def up
    remove_column :petition_emails, :subject
    remove_column :petition_emails, :body
  end

  def down
    add_column :petition_emails, :subject, :string
    add_column :petition_emails, :body, :text
  end
end
