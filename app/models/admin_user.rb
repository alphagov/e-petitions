class AdminUser < ActiveRecord::Base
  SYSADMIN_ROLE = 'sysadmin'
  MODERATOR_ROLE = 'moderator'
  REVIEWER_ROLE = 'reviewer'
  ROLES = [SYSADMIN_ROLE, MODERATOR_ROLE, REVIEWER_ROLE]

  class CannotDeleteCurrentUser < RuntimeError; end
  class MustBeAtLeastOneAdminUser < RuntimeError; end

  devise :trackable, :timeoutable

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

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, email: true
  validates :role, presence: true, inclusion: { in: ROLES }

  before_save :reset_persistence_token, unless: :persistence_token?

  scope :by_name, -> { order(:last_name, :first_name) }
  scope :by_role, ->(role) { where(role: role).order(:id) }

  class << self
    def timeout_in
      Site.login_timeout.seconds
    end

    def find_or_create_from!(provider, auth_data)
      email = auth_data.fetch(:uid).downcase
      groups = fetch_multi(auth_data, :groups)
      retried = false

      begin
        find_or_initialize_by(email: email).tap do |user|
          user.first_name = fetch_single(auth_data, :first_name)
          user.last_name = fetch_single(auth_data, :last_name)

          if (groups & provider.sysadmin).any?
            user.role = SYSADMIN_ROLE
          elsif (groups & provider.moderator).any?
            user.role = MODERATOR_ROLE
          elsif (groups & provider.reviewer).any?
            user.role = REVIEWER_ROLE
          end

          user.save!
        end
      rescue ActiveRecord::RecordNotUnique => e
        return nil if retried
        retried = true
        retry
      end
    rescue ActiveRecord::RecordInvalid => e
      Appsignal.send_exception(e) and return nil
    end

    private

    def fetch_single(auth_data, key)
      fetch_multi(auth_data, key).first
    end

    def fetch_multi(auth_data, key)
      Array.wrap(auth_data.info.fetch(key))
    end
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

  def email=(value)
    super(value.to_s.downcase)
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
