require 'spec_helper'

describe Captcha do

  describe ".verify" do
    # These test will pass with a live connection to the Captcha server and have been commented out for the source code reelase.
    it "returns true if the user input is valid" do
      user_input = 'vnqp28'
      #Captcha.verify(user_input, 'wibble').should be_true
    end

    it "returns false when the user input is blank" do
      #user_input = ''
      #Captcha.verify(user_input, 'wibble').should be_false
    end
  end

end
