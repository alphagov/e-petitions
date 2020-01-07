class ChangeUrlDefaults < ActiveRecord::Migration[5.2]
  def change
    change_column_default :sites, :url,
      from: %[https://petition.parliament.uk],
      to:   %[https://petition.parliament.wales]

    change_column_default :sites, :email_from,
      from: %["Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>],
      to:   %["Petitions: Welsh Government and Parliament" <no-reply@petition.parliament.wales>]

    change_column_default :sites, :feedback_email,
      from: %["Petitions: UK Government and Parliament" <petitionscommittee@parliament.uk>],
      to:   %["Petitions: Welsh Government and Parliament" <petitionscommittee@parliament.wales>]

    change_column_default :sites, :moderate_url,
      from: %[https://moderate.petition.parliament.uk],
      to:   %[https://moderate.petition.parliament.wales]
  end
end
