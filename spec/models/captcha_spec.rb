require 'rails_helper'

describe Captcha do

  describe ".verify" do
    it "returns true if the user input is valid" do
      user_input = 'ld48su'
      Captcha.verify(user_input, 'wibble').should be_true
    end

    it "returns false when the user input is blank" do
      user_input = ''
      Captcha.verify(user_input, 'wibble').should be_false
    end
  end

end
