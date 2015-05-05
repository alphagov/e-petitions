class PetitionSponsorValidator < ActiveModel::Validator
  def validate(sponsor_emails)
    if !has_minimum_number_sponsor_emails
      record.errors[:name] << "less than required amount of sponsor emails"
    elsif !has_unique_sponsor_emails
      record.errors[:name] << "sponsor email addresses are not unique"
    elsif !has_valid_formatted_sponsor_emails
      record.errors[:name] << "sponsor email addresses are not well formed"
    end
  end

  def has_minimum_number_sponsor_emails
    sponsor_emails.count < AppConfig.sponsor_count_min ? true : false
  end

  def has_unique_sponsor_emails
    sponsor_emails.uniq < sponsor_emails ? true : false
  end

  def has_valid_formatted_sponsor_emails
    #TAKEN FROM concerns/email_encrypter.rb
    #sponsor_emails.each do |email|
    #  validates_format_of :email,
    #                      with: Authlogic::Regex.email,
    #                      unless: 'email.blank?',
    #                      message: "Email not recognised."
    #end
      
    #if !sponsor_emails.valid_format?
    #  errors.add(:sponsor_emails, "sponsor email addresses are not well formed")
    #end
    true
  end
end
