class ChangeUrlDefaultsYetAgain < ActiveRecord::Migration[5.2]
  def change
    change_column_default :sites, :url_en,
      from: %[https://petition.parliament.wales],
      to:   %[https://petition.senedd.wales]

    change_column_default :sites, :email_from_en,
      from: %["Petitions: Welsh Parliament" <no-reply@petition.parliament.wales>],
      to: %["Petitions: Welsh Parliament" <no-reply@petition.senedd.wales>]

    change_column_default :sites, :feedback_email,
      from: %["Petitions: Welsh Parliament" <petitionscommittee@parliament.uk>],
      to:   %["Petitions: Welsh Parliament" <petitionscommittee@senedd.wales>]

    change_column_default :sites, :moderate_url,
      from: %[https://moderate.petition.parliament.wales],
      to:   %[https://moderate.petition.senedd.wales]
  end
end
