class AddTranslatedPetitionEmailColumns < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  class PetitionEmail < ActiveRecord::Base; end

  def up
    add_column :petition_emails, :subject_en, :string
    add_column :petition_emails, :subject_cy, :string

    add_column :petition_emails, :body_en, :text
    add_column :petition_emails, :body_cy, :text

    change_column_null :petition_emails, :subject, true

    PetitionEmail.find_each do |email|
      email.update!(
        subject_en: email.subject,
        subject_cy: email.subject,
        body_en: email.body,
        body_cy: email.body
      )
    end

    change_column_null :petition_emails, :subject_en, false
    change_column_null :petition_emails, :subject_cy, false
  end

  def down
    PetitionEmail.find_each do |email|
      email.update!(
        subject: email.subject_en,
        body: email.body_en
      )
    end

    change_column_null :petition_emails, :subject, false

    remove_column :petition_emails, :subject_en
    remove_column :petition_emails, :subject_cy

    remove_column :petition_emails, :body_en
    remove_column :petition_emails, :body_cy
  end
end
