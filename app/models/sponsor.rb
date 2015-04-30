# == Schema Information
#
# Table name: sponsors
#
#  id               :integer          not null, primary key
#  encrypted_email  :string(255)
#  perishable_token :string(255)
#  petition_id      :integer
#  signature_id     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null


class Sponsor < ActiveRecord::Base

  before_create :set_perishable_token

  attr_encrypted :email,
                 key: AppConfig.email_encryption_key,
                 attribute: "encrypted_email",
                 marshal: true,
                 marshaler: EmailDowncaser

  # = Relationships =
  belongs_to :petition
  belongs_to :signature

  # = Validations =
  validates :email, presence: true
  validates_presence_of :petition, message: "Needs a petition"

  validates :encrypted_email,
            uniqueness: { scope: :petition,
                          message: "Sponsor Emails for Petition should be unique" }

  validates_format_of :email,
                      with: Authlogic::Regex.email,
                      unless: 'email.blank?',
                      message: "Email not recognised."

  # = Finders =
  scope :for_email, ->(email) { where(encrypted_email: Signature.encrypt_email(email)) }

  # = Methods =

  # NOTE: These methods for the encrypted_email attribute are
  #       defined here to prevent attr_encrypted from defining
  #       it's own attribute accessors using `attr_accessor`
  # TODO: Remove these methods when attr_encrypted is fixed
  def encrypted_email
    super
  end

  def encrypted_email=(value)
    super
  end

  def encrypted_email?
    super
  end


  private
  def set_perishable_token
    self.perishable_token = Authlogic::Random.friendly_token
  end

end
