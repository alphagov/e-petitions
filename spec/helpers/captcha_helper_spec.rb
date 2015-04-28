require 'rails_helper'

describe CaptchaHelper do

  describe "#captcha_image" do
    let(:markup){ helper.captcha_image('wibble') }

    it "generates an image tag for image.captchas.net" do
      expect(markup.include?("<img")).to be_truthy
      expect(markup.include?('src="https://image.captchas.net/?client=xxxxx&amp;random=wibble')).to be_truthy
    end

    it "makes the captcha purple" do
      expect(markup.include?('color=781D7E')).to be_truthy
    end

    it "specifies a custom alphabet for the captcha" do
      expect(markup.include?('alphabet=abcdefghijklmnopqrstuvwxyz1234567890')).to be_truthy
    end
  end

  describe "#captcha_audio" do
    let(:markup){ helper.captcha_audio('wibble') }

    it "generates a link tag for audio.captchas.net" do
      expect(markup.include?("<a href=\"https://audio.captchas.net/?client=xxxxx&amp;random=wibble")).to be_truthy
    end

    it "has captcha_audio id" do
      expect(markup.include?('id="captcha_audio"')).to be_truthy
    end

    it "specifies a custom alphabet for the captcha" do
      expect(markup.include?('alphabet=abcdefghijklmnopqrstuvwxyz1234567890')).to be_truthy
    end

    it "sets the link target to _blank" do
      markup.include?('target="_blank"')
    end
  end

end
