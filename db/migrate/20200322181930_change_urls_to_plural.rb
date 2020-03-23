class ChangeUrlsToPlural < ActiveRecord::Migration[5.2]
  def change
    change_column_default :sites, :url_en,
      from: %[https://petition.senedd.wales],
      to:   %[https://petitions.senedd.wales]

    change_column_default :sites, :url_cy,
      from: %[https://deiseb.senedd.cymru],
      to:   %[https://deisebau.senedd.cymru]

    change_column_default :sites, :email_from_en,
      from: %["Petitions: Senedd" <no-reply@petition.senedd.wales>],
      to: %["Petitions: Senedd" <no-reply@petitions.senedd.wales>]

    change_column_default :sites, :email_from_cy,
      from: %["Deisebau: Senedd" <dim-ateb@deiseb.senedd.cymru>],
      to: %["Deisebau: Senedd" <dim-ateb@deisebau.senedd.cymru>]

    change_column_default :sites, :moderate_url,
      from: %[https://moderate.petition.senedd.wales],
      to:   %[https://moderate.petitions.senedd.wales]
  end
end
