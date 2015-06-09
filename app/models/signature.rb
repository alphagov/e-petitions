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
#  email            :string(255)
#

class Signature < ActiveRecord::Base

  include PerishableTokenGenerator

  has_perishable_token
  has_perishable_token called: 'unsubscribe_token'

  PENDING_STATE = 'pending'
  VALIDATED_STATE = 'validated'
  STATES = [PENDING_STATE, VALIDATED_STATE]

  # = Relationships =
  belongs_to :petition
  has_one :sponsor

  # = Validations =
  include Staged::Validations::Email
  include Staged::Validations::SignerDetails
  include Staged::Validations::MultipleSigners
  validates_inclusion_of :state, :in => STATES, :message => "'%{value}' not recognised"

  # = Finders =
  scope :validated, -> { where(state: VALIDATED_STATE) }
  scope :pending, -> { where(state: PENDING_STATE) }
  scope :notify_by_email, -> { where(notify_by_email: true) }
  scope :for_email, ->(email) { where(email: email) }
  scope :need_emailing, ->(job_datetime) {
    validated.notify_by_email.where('last_emailed_at is null or last_emailed_at < ?', job_datetime)
  }
  scope :in_days, ->(number_of_days) { validated.where("updated_at > ?", number_of_days.day.ago) }
  scope :matching, ->(signature) { where(email: signature.email,
                                         name: signature.name,
                                         petition_id: signature.petition_id) }

  # = Methods =
  attr_accessor :uk_citizenship

  def email=(value)
    super(value.to_s.downcase)
  end

  def postcode=(value)
    super(value.to_s.gsub(/\s+/, "").upcase)
  end

  def creator?
    petition.creator_signature == self
  end

  def sponsor?
    petition.sponsor_signatures.exists? self.id
  end

  def pending?
    state == PENDING_STATE
  end

  def validated?
    state == VALIDATED_STATE
  end

  def unsubscribed?
    notify_by_email == false
  end

  def validate!
    self.update_columns(state: Signature::VALIDATED_STATE)
    self.touch
  end

  def unsubscribe!
    self.update(notify_by_email: false)
  end

  def constituency
    @constituency ||= ConstituencyApi::Client.constituencies(self.postcode).first
  rescue ConstituencyApi::ConstituencyApiError => e
    Rails.logger.error("Failed to fetch constituency - #{e}")
    nil
  end
end

