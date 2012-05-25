module CaptchaHelper

  def captcha_image(random_string)
    image_tag "https://image.captchas.net/?client=#{Captcha::USERNAME}&random=#{random_string}&color=781D7E&alphabet=#{Captcha::ALPHABET}",
              :id => 'captcha_image'
  end

  def captcha_audio(random_string)
    link_to 'Play audio challenge',
            "https://audio.captchas.net/?client=#{Captcha::USERNAME}&random=#{random_string}&alphabet=#{Captcha::ALPHABET}",
            :id => 'captcha_audio', :target => '_blank'
  end

end
