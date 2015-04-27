require 'digest/md5'

class Captcha
  USERNAME = 'xxxxx'
  SECRET   = 'xxxxx'
  ALPHABET = 'abcdefghijklmnopqrstuvwxyz1234567890'
  CHARACTER_COUNT = 6

  def self.verify(user_inputted_text, captcha_random_string)
    return true if skip_captcha_verification?
    user_inputted_text == get_captcha_text(captcha_random_string)
  end

  def self.get_captcha_text random_string
    if bad_character_count?
      raise "Character count of #{CHARACTER_COUNT} is outside the range of 1-16"
    end

    input = "#{SECRET}#{random_string}"
    if custom_alphabet_or_character_count?
      input << ":#{ALPHABET}:#{CHARACTER_COUNT}"
    end

    bytes = Digest::MD5.hexdigest(input).slice(0..(2*CHARACTER_COUNT - 1)).scan(/../)
    bytes.map { |byte| ALPHABET[byte.hex % ALPHABET.size].chr }.to_s
  end

  def self.skip_captcha_verification?
    AppConfig.has_setting?(:skip_recaptcha_verify) && AppConfig.skip_recaptcha_verify > 0
  end

  private

  def self.bad_character_count?
    CHARACTER_COUNT < 1 || CHARACTER_COUNT > 16
  end

  def self.custom_alphabet_or_character_count?
    ALPHABET != 'abcdefghijklmnopqrstuvwxyz' || CHARACTER_COUNT != 6
  end
end
