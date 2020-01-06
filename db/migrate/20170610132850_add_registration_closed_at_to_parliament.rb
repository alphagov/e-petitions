class AddRegistrationClosedAtToParliament < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base; end

  def up
    add_column :parliaments, :registration_closed_at, :datetime

    parliament = Parliament.first!
    parliament.update!(registration_closed_at: "2017-05-22T23:59:59.999999+01:00")
  end

  def down
    remove_column :parliaments, :registration_closed_at
  end
end
