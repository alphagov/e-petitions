class RemoveGetAnMpEmailSentAtFromPetitions < ActiveRecord::Migration
  def self.up
    remove_column :petitions, :get_an_mp_email_sent_at
  end
  
  def self.down
    add_column :petitions, :get_an_mp_email_sent_at, :datetime
  end
end
