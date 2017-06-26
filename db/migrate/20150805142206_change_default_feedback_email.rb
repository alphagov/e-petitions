class ChangeDefaultFeedbackEmail < ActiveRecord::Migration[4.2]
  def up
    change_column_default :sites, :feedback_email, '"Petitions: UK Government and Parliament" <petitionscommittee@parliament.uk>'
  end

  def down
    change_column_default :sites, :feedback_email, '"Petitions: UK Government and Parliament" <feedback@petition.parliament.uk>'
  end
end
