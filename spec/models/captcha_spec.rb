require 'rails_helper'

describe Captcha do

  describe ".verify" do
    it "returns true if the user input is valid" do
      user_input = 'ld48su'
      expect(Captcha.verify(user_input, 'wibble')).to be_truthy
    end

    it "returns false when the user input is blank" do
      user_input = ''
      expect(Captcha.verify(user_input, 'wibble')).to be_falsey
    end
  end

end
