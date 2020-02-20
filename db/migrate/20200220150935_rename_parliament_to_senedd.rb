class RenameParliamentToSenedd < ActiveRecord::Migration[5.2]
  def change
    change_column_default :sites, :title_en,
      from: %[Petition parliament],
      to:   %[Petition the Senedd]

    change_column_default :sites, :title_cy,
      from: %[Senedd ddeiseb],
      to: %[Deisebu'r Senedd]

    change_column_default :sites, :email_from_en,
      from: %["Petitions: Welsh Parliament" <petitionscommittee@parliament.uk>],
      to:   %["Petitions: Senedd" <no-reply@petition.senedd.wales>]

    change_column_default :sites, :email_from_cy,
      from: %["Deisebau: Senedd Cymru" <dim-ateb@deiseb.senedd.cymru>],
      to:   %["Deisebau: Senedd" <dim-ateb@deiseb.senedd.cymru>]

    change_column_default :sites, :feedback_email,
      from: %["Petitions: Welsh Parliament" <petitionscommittee@senedd.wales>],
      to:   %["Petitions: Senedd" <petitions@senedd.wales>]
  end
end
