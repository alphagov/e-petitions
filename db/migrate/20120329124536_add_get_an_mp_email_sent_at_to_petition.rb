class AddGetAnMpEmailSentAtToPetition < ActiveRecord::Migration
  def self.up
    add_column :petitions, :get_an_mp_email_sent_at, :datetime
    add_index :petitions, :get_an_mp_email_sent_at
  end

  def self.down
    remove_index :petitions, :get_an_mp_email_sent_at
    remove_column :petitions, :get_an_mp_email_sent_at
  end
end
