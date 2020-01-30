class ChangeUrlDefaultsAgain < ActiveRecord::Migration[5.2]
  def change
    change_column_default :sites, :email_from_en,
      from: %["Petitions: Welsh Government and Parliament" <no-reply@petition.parliament.wales>],
      to:   %["Petitions: Welsh Parliament" <no-reply@petition.parliament.wales>]

    change_column_default :sites, :email_from_cy,
      from: %["Deisebau: Llywodraeth a Senedd Cymru" <dim-ateb@deiseb.senedd.cymru>],
      to:   %["Deisebau: Senedd Cymru" <dim-ateb@deiseb.senedd.cymru>]

    change_column_default :sites, :feedback_email,
      from: %["Petitions: Welsh Government and Parliament" <petitionscommittee@parliament.wales>],
      to:   %["Petitions: Welsh Parliament" <petitionscommittee@parliament.wales>]
  end
end
