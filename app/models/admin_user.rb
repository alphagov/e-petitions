class AdminUser < ActiveRecord::Base
  DISABLED_LOGIN_COUNT = 5
  SYSADMIN_ROLE = 'sysadmin'
  MODERATOR_ROLE = 'moderator'
  ROLES = [SYSADMIN_ROLE, MODERATOR_ROLE]
  PASSWORD_REGEX = /\A.*(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).*\z/

  class CannotDeleteCurrentUser < RuntimeError; end
  class MustBeAtLeastOneAdminUser < RuntimeError; end

  acts_as_authentic do |config|
    config.crypto_provider = ::Authlogic::CryptoProviders::SCrypt

    config.check_passwords_against_database = true
    config.ignore_blank_passwords = true
    config.logged_in_timeout = Site.login_timeout
    config.require_password_confirmation = true

    config.validates_length_of :password, minimum: 8, unless: ->(u) { u.password.blank? }
    config.validates_confirmation_of :password, unless: ->(u) { u.password.blank? }
    config.validates :email, email: true, uniqueness: { case_sensitive: false }
    config.validates_uniqueness_of :email, uniqueness: { case_sensitive: false }
  end

  # = Validations =
  validates_presence_of :email, :first_name, :last_name
  validates_presence_of :password, on: :create
  validates_format_of :password, with: PASSWORD_REGEX, allow_blank: true
  validates_inclusion_of :role, in: ROLES

  # = Callbacks =
  before_update if: :crypted_password_changed? do
    self.force_password_reset = false
    self.password_changed_at = Time.current
  end

  # = Finders =
  scope :by_name, -> { order(:last_name, :first_name) }
  scope :by_role, ->(role) { where(role: role).order(:id) }

  # = Methods =
  def current_password
    defined?(@current_password) ? @current_password : nil
  end

  def current_password=(value)
    @current_password = value
  end

  def update_with_password(attrs)
    if attrs[:password].blank?
      attrs.delete(:password)
      attrs.delete(:password_confirmation) if attrs[:password_confirmation].blank?
    end

    self.attributes = attrs
    self.valid?

    if current_password.blank?
      errors.add(:current_password, :blank)
    elsif !valid_password?(current_password)
      errors.add(:current_password, :invalid)
    elsif current_password == password
      errors.add(:password, :taken)
    end

    errors.empty? && save(validate: false)
  end

  def destroy(current_user: nil)
    if self == current_user
      raise CannotDeleteCurrentUser, "Cannot delete current user"
    elsif self.class.count < 2
      raise MustBeAtLeastOneAdminUser, "There must be at least one admin user"
    else
      super()
    end
  end

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

  def elapsed_time(now = Time.current)
    (now - last_request_at).floor
  end

  def time_remaining(now = Time.current)
    [Site.login_timeout - elapsed_time(now), 0].max
  end
end
