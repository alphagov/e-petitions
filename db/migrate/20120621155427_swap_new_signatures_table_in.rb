class SwapNewSignaturesTableIn < ActiveRecord::Migration
  def self.up
    execute "RENAME TABLE signatures TO signatures_pre_encryption"
    execute "RENAME TABLE encrypted_signatures TO signatures"
  end

  def self.down
    execute "RENAME TABLE signatures TO encrypted_signatures"
    execute "RENAME TABLE signatures_pre_encryption TO signatures"
  end
end
