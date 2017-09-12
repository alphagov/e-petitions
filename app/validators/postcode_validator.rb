class PostcodeValidator < ActiveModel::EachValidator
  STANDARD = "([A-Z]{1,2}[0-9][0-9A-Z]?[0-9][A-BD-HJLNP-UW-Z]{2})"
  BFPO     = "(BFPO?(C\/O)?[0-9]{1,4})"
  GIROBANK = "(GIR0AA)"
  PATTERN  = /\A(#{STANDARD}|#{BFPO}|#{GIROBANK})\Z/i

  def validate_each(record, attribute, value)
    unless value.to_s =~ PATTERN
      record.errors.add(attribute, (options[:message] || :invalid))
    end
  end
end
