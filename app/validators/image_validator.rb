require 'marcel'
require 'mini_magick'

class ImageValidator < ActiveModel::EachValidator
  include ActiveSupport::NumberHelper

  def validate_each(record, attribute, value)
    return true if !value.attached?

    errors_options[:message] = options[:message] if options[:message].present?

    read_image(record, attribute, value) do |image|
      validate_content_type(record, attribute, image) if options[:content_type]
      validate_byte_size(record, attribute, image) if options[:byte_size]
      validate_dimensions(record, attribute, image) if options[:dimensions]
    end
  end

  private

  def read_image(record, attribute, attachment)
    return unless record.attachment_changes.key?(attachment.name)

    changes = record.attachment_changes[attachment.name]
    attachable = changes.attachable

    if attachable.is_a?(Hash)
      path = attachable[:io].path
    else
      path = attachable.tempfile.path
    end

    image = MiniMagick::Image.new(path)

    if image.valid?
      yield image
    else
      record.errors.add attribute, :invalid
    end
  end

  def validate_content_type(record, attribute, image)
    mime_type = Marcel::MimeType.for(Pathname.new(image.path))

    valid = \
      case options[:content_type]
      when String
        options[:content_type] == mime_type
      when Regexp
        options[:content_type].match?(mime_type)
      when Array
        options[:content_type].include?(mime_type)
      else
        false
      end

    unless valid
      record.errors.add attribute, :invalid
    end
  end

  def validate_byte_size(record, attribute, image)
    if image.size > options[:byte_size]
      record.errors.add attribute, :too_large, max_size: max_size
    end
  end

  def validate_dimensions(record, attribute, image)
    if image.width < min_width
      record.errors.add attribute, :too_narrow, width: image.width, min_width: min_width
    end

    if image.width > max_width
      record.errors.add attribute, :too_wide, width: image.width, max_width: max_width
    end

    if image.height < min_height
      record.errors.add attribute, :too_short, height: image.height, min_height: min_height
    end

    if image.height > max_height
      record.errors.add attribute, :too_tall, height: image.height, max_height: max_height
    end

    image_ratio = image.width.fdiv(image.height)
    human_ratio = number_to_human(image_ratio)

    if ratio.exclude?(image_ratio)
      record.errors.add attribute, :incorrect_ratio, ratio: human_ratio, min_ratio: min_ratio, max_ratio: max_ratio
    end
  end

  def dimensions
    options[:dimensions]
  end

  def min_width
    dimensions[:width].first
  end

  def max_width
    dimensions[:width].last
  end

  def min_height
    dimensions[:height].first
  end

  def max_height
    dimensions[:height].last
  end

  def ratio
    dimensions[:ratio]
  end

  def min_ratio
    number_to_human(dimensions[:ratio].first)
  end

  def max_ratio
    number_to_human(dimensions[:ratio].last)
  end

  def max_size
    number_to_human_size(options[:byte_size])
  end
end
