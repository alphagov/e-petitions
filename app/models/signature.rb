# == Schema Information
#
# Table name: signatures
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)     not null
#  state            :string(10)      default("pending"), not null
#  perishable_token :string(255)
#  postcode         :string(255)
#  country          :string(255)
#  ip_address       :string(20)
#  petition_id      :integer(4)
#  created_at       :datetime
#  updated_at       :datetime
#  notify_by_email  :boolean(1)      default(TRUE)
#  last_emailed_at  :datetime
#  encrypted_email  :string(255)
#

class Signature < ActiveRecord::Base

  include EmailEncrypter
  include PerishableTokenGenerator

  PENDING_STATE = 'pending'
  VALIDATED_STATE = 'validated'
  STATES = [PENDING_STATE, VALIDATED_STATE]

  # = Relationships =
  belongs_to :petition
  has_one :sponsor

  # = Validations =
  include Staged::Validations::SignerDetails
  include Staged::Validations::MultipleSigners
  validates_inclusion_of :state, :in => STATES, :message => "'%{value}' not recognised"

  # = Finders =
  scope :validated, -> { where(state: VALIDATED_STATE) }
  scope :pending, -> { where(state: PENDING_STATE) }
  scope :notify_by_email, -> { where(notify_by_email: true) }
  scope :need_emailing, ->(job_datetime) {
    validated.notify_by_email.where('last_emailed_at is null or last_emailed_at < ?', job_datetime)
  }
  scope :in_days, ->(number_of_days) { validated.where("updated_at > ?", number_of_days.day.ago) }
  scope :matching, ->(signature) { where(encrypted_email: signature.encrypted_email,
                                         name: signature.name, 
                                         petition_id: signature.petition_id) }

  # callbacks
  before_create :generate_unsubscribe_token

  # = Methods =
  attr_accessor :uk_citizenship

  def creator?
    petition.creator_signature == self
  end

  def pending?
    state == PENDING_STATE
  end

  def validated?
    state == VALIDATED_STATE
  end

  def postal_district
    postcode.upcase[0..-4].match(/[A-Z]{1,2}[0-9]{1,2}[A-Z]?/).to_s
  end

  def generate_unsubscribe_token
    self.unsubscribe_token = Authlogic::Random.friendly_token
  end
end
