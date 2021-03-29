require 'uri'

class UrlValidator < ActiveModel::EachValidator
  def self.valid?(value)
    URI::HTTP === URI.parse(value)
  rescue URI::InvalidURIError => e
    false
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    unless self.class.valid?(value)
      record.errors.add(attribute, :invalid)
    end
  end
end
