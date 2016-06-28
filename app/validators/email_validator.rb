class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value =~ EMAIL_REGEX
      email = parsed_email(value)
      record.errors.add :email, :disposable if disposable_domain?(email)
      record.errors.add :email, :plus_address if plus_address?(email)
    else
      record.errors.add attribute, :invalid
    end
  rescue Mail::Field::ParseError
    record.errors.add attribute, :invalid
  end

  def plus_address?(parsed_email)
    parsed_email.local.include? '+'
  end

  def disposable_domain?(parsed_email)
    disposable_domains.include?(parsed_email.domain)
  end

  def parsed_email(email)
    Mail::Address.new(email)
  end

  def disposable_domains
    Rails.application.config.x.disposable_domains
  end
end
