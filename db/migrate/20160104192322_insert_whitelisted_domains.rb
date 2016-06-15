class InsertWhitelistedDomains < ActiveRecord::Migration
  class Domain < ActiveRecord::Base
    def self.allowed
      where(state: 'allow')
    end
  end

  def up
    now = Time.current

    %w[
      com
      co.uk
      net
      aol.com
      blueyonder.co.uk
      btinternet.com
      gmail.com
      googlemail.com
      hotmail.co.uk
      hotmail.com
      icloud.com
      live.co.uk
      live.com
      me.com
      msn.com
      ntlworld.com
      outlook.com
      sky.com
      talktalk.net
      tiscali.co.uk
      virginmedia.com
      yahoo.co.uk
      yahoo.com
    ].each do |name|
      Domain.create!(name: name, state: 'allow', resolved_at: now)
    end
  end

  def down
    Domain.allowed.delete_all
  end
end
