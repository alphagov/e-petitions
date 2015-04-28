# == Schema Information
#
# Table name: admin_users
#
#  id                   :integer(4)      not null, primary key
#  email                :string(255)     not null
#  persistence_token    :string(255)
#  crypted_password     :string(255)
#  password_salt        :string(255)
#  login_count          :integer(4)      default(0)
#  failed_login_count   :integer(4)      default(0)
#  current_login_at     :datetime
#  last_login_at        :datetime
#  current_login_ip     :string(255)
#  last_login_ip        :string(255)
#  first_name           :string(255)
#  last_name            :string(255)
#  role                 :string(10)      not null
#  force_password_reset :boolean(1)      default(TRUE)
#  password_changed_at  :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

class AdminUser < ActiveRecord::Base
  DISABLED_LOGIN_COUNT = 5
  ADMIN_ROLE = 'admin'
  SYSADMIN_ROLE = 'sysadmin'
  THRESHOLD_ROLE = 'threshold'

  acts_as_authentic do |config|
    config.merge_validates_length_of_password_field_options :minimum => 8
    config.ignore_blank_passwords = true
    config.merge_validates_uniqueness_of_email_field_options :case_sensitive => true

    # Add conditions to the default validations to tidy up output.
    config.merge_validates_format_of_email_field_options :unless => Proc.new { |user| user.email.blank? }
    config.merge_validates_length_of_email_field_options :unless => Proc.new { |user| user.email.blank? }
    config.merge_validates_length_of_password_field_options :unless => Proc.new { |user| user.password.blank? }
    config.merge_validates_confirmation_of_password_field_options :unless => Proc.new { |user| user.password.blank? }
  end

  # = Relationships =
  has_and_belongs_to_many :departments

  # = Validations =
  validates_presence_of :password, :on => :create
  validates_presence_of :email, :first_name, :last_name
  # password must have at least one digit, one alphabetical lower and upcase case character and one special character
  # see http://www.zorched.net/2009/05/08/password-strength-validation-with-regular-expressions/
  validates_format_of :password, :with => /^.*(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).*$/,
                      :message => 'must contain at least one digit, a lower and upper case letter and a special character',
                      :allow_blank => true
  ROLES = [ADMIN_ROLE, SYSADMIN_ROLE, THRESHOLD_ROLE]
  validates_inclusion_of :role, :in => ROLES, :message => "'%{value}' is invalid"

  # = Finders =
  scope :by_name, :order => 'last_name, first_name'
  scope :by_role, lambda { |role| { :conditions => ['role = ?', role] }}

  # = Methods =

  def name
    "#{last_name}, #{first_name}"
  end

  def is_a_sysadmin?
    self.role == 'sysadmin'
  end

  def is_a_threshold?
    self.role == 'threshold'
  end

  def has_to_change_password?
    self.force_password_reset or (self.password_changed_at and self.password_changed_at < 9.months.ago)
  end

  def can_take_petitions_down?
    is_a_sysadmin? || is_a_threshold?
  end

  def can_edit_responses?
    is_a_sysadmin? || is_a_threshold?
  end

  def can_see_all_trending_petitions?
    is_a_sysadmin? || is_a_threshold?
  end

  def account_disabled
    self.failed_login_count >= DISABLED_LOGIN_COUNT
  end

  def account_disabled=(flag)
    self.failed_login_count = (flag == "0" or !flag) ? 0 : DISABLED_LOGIN_COUNT
  end
end
