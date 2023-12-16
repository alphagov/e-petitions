class AdminUser < ActiveRecord::Base
  DISABLED_LOGIN_COUNT = 5
  SYSADMIN_ROLE = 'sysadmin'
  MODERATOR_ROLE = 'moderator'
  REVIEWER_ROLE = 'reviewer'
  ROLES = [SYSADMIN_ROLE, MODERATOR_ROLE, REVIEWER_ROLE]
  PASSWORD_REGEX = /\A.*(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).*\z/

  class CannotDeleteCurrentUser < RuntimeError; end
  class MustBeAtLeastOneAdminUser < RuntimeError; end

  devise :database_authenticatable, :encryptable, :trackable, :timeoutable, :lockable

  with_options dependent: :restrict_with_exception do
    with_options foreign_key: :moderated_by_id do
      has_many :petitions
      has_many :archived_petitions, class_name: "Archived::Petition"
    end
  end

  # = Validations =
  validates :first_name, :last_name, presence: true
  validates :email, presence: true, email: true
  validates :email, uniqueness: { case_sensitive: false }
  validates :password, presence: true, on: [:create, :update_password]
  validates :password, length: { minimum: 8, allow_blank: true }
  validates :password, format: { with: PASSWORD_REGEX, allow_blank: true }
  validates :password, confirmation: true, on: :update_password
  validates :role, inclusion: { in: ROLES }

  validate on: :update_password do
    errors.add(:current_password, :blank) if current_password.blank?
    errors.add(:current_password, :invalid) unless valid_password?(current_password)
    errors.add(:password, :taken) if valid_password?(password)
  end

  # = Callbacks =
  before_save :clear_locked_at, if: :enabling_account?
  before_save :set_locked_at, if: :disabling_account?
  before_save :reset_persistence_token, unless: :persistence_token?
  before_update :reset_password_tracking, if: :encrypted_password_changed?

  # = Finders =
  scope :by_name, -> { order(:last_name, :first_name) }
  scope :by_role, ->(role) { where(role: role).order(:id) }

  # = Methods =
  def self.timeout_in
    Site.login_timeout.seconds
  end

  def reset_password_tracking
    self.force_password_reset = false
    self.password_changed_at = Time.current
  end

  def reset_persistence_token
    self.persistence_token = SecureRandom.hex(64)
  end

  def reset_persistence_token!
    SecureRandom.hex(64).tap { |token| update_column(:persistence_token, token) }
  end

  def valid_persistence_token?(token)
    persistence_token == token
  end

  def current_password
    defined?(@current_password) ? @current_password : nil
  end

  def current_password=(value)
    @current_password = value
  end

  def valid_password?(password)
    encryptor_class.compare(encrypted_password_in_database, password, nil, password_salt_in_database, nil)
  end

  def update_password(params)
    assign_attributes(params)

    save(context: :update_password).tap do
      self.current_password = nil
      self.password = nil
      self.password_confirmation = nil
    end
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

  def rfc822
    %Q["#{first_name} #{last_name}" <#{email}>]
  end

  def is_a_sysadmin?
    self.role == 'sysadmin'
  end

  def is_a_moderator?
    self.role == 'moderator'
  end

  def is_a_reviewer?
    self.role == 'reviewer'
  end

  def has_to_change_password?
    self.force_password_reset or (self.password_changed_at and self.password_changed_at < 9.months.ago)
  end

  def can_take_petitions_down?
    is_a_sysadmin? || is_a_moderator?
  end

  def can_remove_petitions?
    is_a_sysadmin?
  end

  def can_edit_responses?
    is_a_sysadmin? || is_a_moderator?
  end

  def can_moderate_petitions?
    is_a_sysadmin? || is_a_moderator?
  end

  def account_disabled
    self.failed_attempts >= DISABLED_LOGIN_COUNT
  end

  def account_disabled=(flag)
    self.failed_attempts = (flag == "0" or !flag) ? 0 : DISABLED_LOGIN_COUNT
  end

  def enabling_account?
    failed_attempts_changed? && failed_attempts.zero?
  end

  def disabling_account?
    failed_attempts_changed? && failed_attempts >= DISABLED_LOGIN_COUNT
  end

  def clear_locked_at
    self.locked_at = nil
  end

  def set_locked_at(now = Time.current)
    self.locked_at = now
  end

  def elapsed_time(last_request_at, now = Time.current)
    (now - last_request_at).floor
  end

  def time_remaining(last_request_at, now = Time.current)
    [Site.login_timeout - elapsed_time(last_request_at, now), 0].max
  end
end
