require 'active_support/core_ext/object/blank'

class DomainAutocorrect
  RULES = {
    /\A([^@]+)@(a(?:i|o|p)l\.(?:com|con|co\.uk))\z/ => 'aol.com',
    /\A([^@]+)@(b(?:r|t|y)?i?n(?:g|t|y)?e(?:r|t)?(?:m|n)e(?:r|t)\.(?:com|con|co\.uk|co))\z/ => 'btinternet.com',
    /\A([^@]+)@((?:f|g)\.?(?:a|m|n)(?:a|i|m|n|s)(?:a|i|l|o|u)(?:i|k|l){0,2}\.(?:cim|clm|comm|com\.uk|com\.com|com|con|vom|cm|co\.uk|co|om|uk))\z/ => 'gmail.com',
    /\A([^@]+)@(goog?le?m(?:a|i|s)(?:a|i)l\.(?:com|con|co\.uk))\z/ => 'googlemail.com',
    /\A([^@]+)@(h(?:i|o)(?:r|t)?(?:m|n)(?:a|i|s)?(?:a|i|u)?(?:k|l){0,2}\.(?:cim|com|con|cm|co))\z/ => 'hotmail.com',
    /\A([^@]+)@(h(?:i|o)(?:r|t)?(?:m|n)(?:a|i|s)?(?:a|i|u)?(?:k|l){0,2}\.?(?:com|con|co)?\.?(?:ik|uk|uj|ul|um|un|yk))\z/ => 'hotmail.co.uk',
    /\A([^@]+)@(i?(?:c|v)l?oul?d\.(?:com|con|co\.uk))\z/ => 'icloud.com',
    /\A([^@]+)@(live\.(?:com|con|co))\z/ => 'live.com',
    /\A([^@]+)@(live\.co\.(?:ik|uk|um|un))\z/ => 'live.co.uk',
    /\A([^@]+)@(mac\.(?:com|con))\z/ => 'mac.com',
    /\A([^@]+)@(me\.(?:com|con))\z/ => 'me.com',
    /\A([^@]+)@(msn\.(?:com|con))\z/ => 'msn.com',
    /\A([^@]+)@(ntlworl?d\.(?:com|con))\z/ => 'ntlworld.com',
    /\A([^@]+)@(out?l?(?:i|o)o+k\.co(?:m|n|\.uk))\z/ => 'outlook.com',
    /\A([^@]+)@(sky\.co(?:m|n))\z/ => 'sky.com',
    /\A([^@]+)@(talktalk\.(?:com|net))\z/ => 'talktalk.net',
    /\A([^@]+)@((?:u|t|y)(?:a|s)?hoo?\.?(?:co)?n?\.?(?:i|u|y)(?:j|k|l|m|n))\z/ => 'yahoo.co.uk',
    /\A([^@]+)@(yahoo\.co(?:m|n)?)\z/ => 'yahoo.com'
  }

  def self.call(email)
    return email if email.blank?

    RULES.each do |pattern, domain|
      if data = pattern.match(email)
        return "#{data[1]}@#{domain}"
      end
    end

    email
  end
end
