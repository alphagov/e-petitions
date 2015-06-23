class AdminUser < ActiveRecord::Base
  DISABLED_LOGIN_COUNT = 5
  SYSADMIN_ROLE = 'sysadmin'
  MODERATOR_ROLE = 'moderator'

  acts_as_authentic do |config|
    config.merge_validates_length_of_password_field_options :minimum => 8
    config.ignore_blank_passwords = true
    config.merge_validates_uniqueness_of_email_field_options :case_sensitive => false

    # Add conditions to the default validations to tidy up output.
    config.merge_validates_format_of_email_field_options :unless => Proc.new { |user| user.email.blank? }
    config.merge_validates_length_of_email_field_options :unless => Proc.new { |user| user.email.blank? }
    config.merge_validates_length_of_password_field_options :unless => Proc.new { |user| user.password.blank? }
    config.merge_validates_confirmation_of_password_field_options :unless => Proc.new { |user| user.password.blank? }
  end

  # = Validations =
  validates_presence_of :password, :on => :create
  validates_presence_of :email, :first_name, :last_name
  # password must have at least one digit, one alphabetical lower and upcase case character and one special character
  # see http://www.zorched.net/2009/05/08/password-strength-validation-with-regular-expressions/
  validates_format_of :password, :with => /\A.*(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).*\z/,
                      :message => 'must contain at least one digit, a lower and upper case letter and a special character',
                      :allow_blank => true
  ROLES = [SYSADMIN_ROLE, MODERATOR_ROLE]
  validates_inclusion_of :role, :in => ROLES, :message => "'%{value}' is invalid"

  # = Finders =
  scope :by_name, -> { order(:last_name, :first_name) }
  scope :by_role, ->(role) { where(role: role).order(:id) }

  # = Methods =

  def name
    "#{last_name}, #{first_name}"
  end

  def pretty_name
    "#{first_name} #{last_name}"
  end

  def is_a_sysadmin?
    self.role == 'sysadmin'
  end

  def is_a_moderator?
    self.role == 'moderator'
  end

  def has_to_change_password?
    self.force_password_reset or (self.password_changed_at and self.password_changed_at < 9.months.ago)
  end

  def can_take_petitions_down?
    is_a_sysadmin? || is_a_moderator?
  end

  def can_edit_responses?
    is_a_sysadmin? || is_a_moderator?
  end

  def account_disabled
    self.failed_login_count >= DISABLED_LOGIN_COUNT
  end

  def account_disabled=(flag)
    self.failed_login_count = (flag == "0" or !flag) ? 0 : DISABLED_LOGIN_COUNT
  end
end
