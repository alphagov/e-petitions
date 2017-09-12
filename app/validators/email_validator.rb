class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value =~ EMAIL_REGEX
      email = parsed_email(value)
      record.errors.add attribute, :plus_address if plus_address?(email)
    else
      record.errors.add attribute, :invalid
    end
  rescue Mail::Field::ParseError
    record.errors.add attribute, :invalid
  end

  def plus_address?(parsed_email)
    parsed_email.local.include? '+'
  end

  def parsed_email(email)
    Mail::Address.new(email)
  end
end
