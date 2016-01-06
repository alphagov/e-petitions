class DebateOutcome < ActiveRecord::Base
  # By default we want the user to upload a '2x' style image, and we can then
  # resize it down with Imagemagick
  COMMONS_IMAGE_SIZE = { w: 1260.0, h: 710.0 }

  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :debated_on, presence: true, if: :debated?
  validates :transcript_url, :video_url, length: { maximum: 500 }

  has_attached_file :commons_image,
    # default_url needs to be a lambda - this way the generated image url will
    # include any asset-digest
    default_url: ->(_) { ActionController::Base.helpers.image_url("graphics/graphic_house-of-commons.jpg") },
    styles: {
      "1x": "#{(COMMONS_IMAGE_SIZE[:w]/2).to_i}x#{(COMMONS_IMAGE_SIZE[:h]/2).to_i}",
      "2x": "#{COMMONS_IMAGE_SIZE[:w]}x#{COMMONS_IMAGE_SIZE[:h]}"
    }

  validates_attachment_content_type :commons_image, content_type: /\Aimage\/.*\Z/
  validate :validate_commons_image_dimensions, unless: Proc.new { |a|
    a.commons_image.blank? || !commons_image.queued_for_write[:original]
  }

  after_create do
    petition.touch(:debate_outcome_at)
  end

  after_save do
    petition.update_columns(debate_state: debate_state)
  end

  def date
    debated_on
  end

  private

  def debate_state
    debated? ? 'debated' : 'none'
  end

  def image_ratio(width, height)
    (width.to_f / height.to_f).round(2)
  end

  def validate_commons_image_dimensions
    # This should be tuned if the images start looking badly scaled
    max_ratio_delta = 0.1

    dimensions = Paperclip::Geometry.from_file(commons_image.queued_for_write[:original].path)

    # Too big:
    errors.add(:commons_image, "Width must be at least #{COMMONS_IMAGE_SIZE[:w]}px (is #{dimensions.width}px)") unless dimensions.width >= COMMONS_IMAGE_SIZE[:w]
    errors.add(:commons_image, "Height must be #{COMMONS_IMAGE_SIZE[:h]}px (is #{dimensions.height}px)") unless dimensions.height >= COMMONS_IMAGE_SIZE[:h]

    expected_ratio = image_ratio(COMMONS_IMAGE_SIZE[:w], COMMONS_IMAGE_SIZE[:h])
    actual_ratio = image_ratio(dimensions.width, dimensions.height)

    min_ratio = (expected_ratio - max_ratio_delta).round(2)
    max_ratio = (expected_ratio + max_ratio_delta).round(2)
    unless (min_ratio..max_ratio).include? actual_ratio
      errors.add(:commons_image, "Width and height ratio of uploaded image is #{actual_ratio} - should be between #{min_ratio} and #{max_ratio}")
    end
  end
end
