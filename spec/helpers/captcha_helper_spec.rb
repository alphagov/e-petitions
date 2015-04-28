require 'rails_helper'

describe CaptchaHelper do

  describe "#captcha_image" do
    let(:markup){ helper.captcha_image('wibble') }

    it "generates an image tag for image.captchas.net" do
      markup.include?("<img").should be_true
      markup.include?('src="https://image.captchas.net/?client=xxxxx&amp;random=wibble').should be_true
    end

    it "makes the captcha purple" do
      markup.include?('color=781D7E').should be_true
    end

    it "specifies a custom alphabet for the captcha" do
      markup.include?('alphabet=abcdefghijklmnopqrstuvwxyz1234567890').should be_true
    end
  end

  describe "#captcha_audio" do
    let(:markup){ helper.captcha_audio('wibble') }

    it "generates a link tag for audio.captchas.net" do
      markup.include?("<a href=\"https://audio.captchas.net/?client=xxxxx&amp;random=wibble").should be_true
    end

    it "has captcha_audio id" do
      markup.include?('id="captcha_audio"').should be_true
    end

    it "specifies a custom alphabet for the captcha" do
      markup.include?('alphabet=abcdefghijklmnopqrstuvwxyz1234567890').should be_true
    end

    it "sets the link target to _blank" do
      markup.include?('target="_blank"')
    end
  end

end
