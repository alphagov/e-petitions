class AdminUser < ActiveRecord::Base
  SYSADMIN_ROLE = 'sysadmin'
  MODERATOR_ROLE = 'moderator'
  REVIEWER_ROLE = 'reviewer'
  ROLES = [SYSADMIN_ROLE, MODERATOR_ROLE, REVIEWER_ROLE]

  class CannotDeleteCurrentUser < RuntimeError; end
  class MustBeAtLeastOneAdminUser < RuntimeError; end

  devise :trackable, :timeoutable, :omniauthable, omniauth_providers: %i[developer]

  # TODO: Drop these columns once rollout of SSO has been completed
  self.ignored_columns = %i[
    encrypted_password password_salt
    force_password_reset password_changed_at
    failed_attempts locked_at
  ]

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
  validates :role, inclusion: { in: ROLES }

  # = Callbacks =
  before_save :reset_persistence_token, unless: :persistence_token?

  # = Finders =
  scope :by_name, -> { order(:last_name, :first_name) }
  scope :by_role, ->(role) { where(role: role).order(:id) }

  # = Methods =
  def self.timeout_in
    Site.login_timeout.seconds
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

  def elapsed_time(last_request_at, now = Time.current)
    (now - last_request_at).floor
  end

  def time_remaining(last_request_at, now = Time.current)
    [Site.login_timeout - elapsed_time(last_request_at, now), 0].max
  end
end
