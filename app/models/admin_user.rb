class AdminUser < ActiveRecord::Base
  DISABLED_LOGIN_COUNT = 5
  SYSADMIN_ROLE = 'sysadmin'
  MODERATOR_ROLE = 'moderator'
  ROLES = [SYSADMIN_ROLE, MODERATOR_ROLE]
  PASSWORD_REGEX = /\A.*(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).*\z/

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
  validates_presence_of :email, :first_name, :last_name
  validates_presence_of :password, on: :create
  validates_format_of :password, with: PASSWORD_REGEX, allow_blank: true
  validates_inclusion_of :role, in: ROLES

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
