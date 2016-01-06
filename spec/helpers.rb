module Helpers
  def commons_image_fixture_path(filename)
    Rails.root.join('spec', 'fixtures', 'images', 'debate_outcome', filename)
  end

  def commons_default_image_url
    ActionController::Base.helpers.image_url('graphics/graphic_house-of-commons.jpg')
  end

  def commons_image_file
    commons_image_fixture_path 'commons_image-2x.jpg'
  end

  def commons_image_file_too_small
    commons_image_fixture_path 'commons_image-too-small.jpg'
  end

  def commons_image_file_wrong_ratio
    commons_image_fixture_path 'commons_image-wrong-ratio.jpg'
  end
end
