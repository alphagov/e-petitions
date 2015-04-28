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
#  notify_by_email  :boolean(1)      default(FALSE)
#  last_emailed_at  :datetime
#  encrypted_email  :string(255)
#

class Signature < ActiveRecord::Base
  PENDING_STATE = 'pending'
  VALIDATED_STATE = 'validated'
  STATES = [PENDING_STATE, VALIDATED_STATE]

  attr_accessible :name, :email, :email_confirmation, :address, :town, :postcode, :country, :humanity, :uk_citizenship, :terms_and_conditions, :notify_by_email
  before_create :set_perishable_token

  class EmailDowncaser
    def self.dump(value)
      value.downcase
    end
    def self.load(value)
      value
    end
  end

  attr_encrypted :email, :key => AppConfig.email_encryption_key, :attribute => "encrypted_email", :marshal => true, :marshaler => EmailDowncaser

  # = Relationships =
  belongs_to :petition

  # = Validations =
  validates_format_of :email, :with => Authlogic::Regex.email, :unless => 'email.blank?', :message => "Email not recognised."
  validates_presence_of :email_confirmation, :on => :create, :message => "%{attribute} must be completed"
  validates_confirmation_of :email, :message => "Email should match confirmation", :on => :create

  validate do |signature|
    matcher = Signature.where(:encrypted_email => signature.encrypted_email, :petition_id => signature.petition_id)
    matcher = matcher.where("signatures.id != ?", signature.id) unless signature.new_record?
    existing_email_address_count = matcher.count
    break if existing_email_address_count == 0
    if existing_email_address_count > 1
      signature.errors.add(:email, 'This email address is not allowed to sign this petition again')
      break
    end
    existing_signature =  matcher.first
    if (existing_signature.name.strip.downcase == signature.name.strip.downcase)
      signature.errors.add(:email, 'You cannot sign this petition again')
      break
    end
    if (existing_signature.postcode.gsub(/\s+/,'').downcase !=
        signature.postcode.gsub(/\s+/,'').downcase)
      signature.errors.add(:email, 'This email address is not allowed to sign this petition again')
      break
    end

  end
  validates_presence_of :name, :email, :country, :message => "%{attribute} must be completed"
  validates_length_of :name, :maximum => 255
  validates_presence_of :postcode, :message => "%{attribute} must be completed", :if => "country == 'United Kingdom'"
  validates_inclusion_of :state, :in => STATES, :message => "'%{value}' not recognised"

  validates_acceptance_of :humanity, :accept => true, :message => "The captcha was not filled in correctly.", :if => :new_record?, :allow_nil => false
  validates_acceptance_of :uk_citizenship, :message => "You must be a British citizen or normally live in the UK to create or sign petitions.", :if => :new_record?, :allow_nil => false
  validates_acceptance_of :terms_and_conditions, :message => "You must accept the terms and conditions.", :if => :new_record?, :allow_nil => false
  validates_presence_of :address, :town, :if => :new_record?, :message => "%{attribute} must be completed"

  # = Finders =
  scope :validated, lambda {{ :conditions => ['state = ?', VALIDATED_STATE] }}
  scope :notify_by_email, lambda {{ :conditions => ['notify_by_email = ?', true] }}
  scope :need_emailing, lambda { |job_datetime|
    validated.notify_by_email.where('last_emailed_at is null or last_emailed_at < ?', job_datetime)
  }
  scope :for_email, lambda { |email| where(:encrypted_email => Signature.encrypt_email(email)) }
  scope :in_days, lambda {|number_of_days| validated.where("updated_at > ?", number_of_days.day.ago) }

  # = Methods =
  attr_accessor :humanity
  attr_accessor :uk_citizenship
  attr_accessor :terms_and_conditions
  attr_accessor :address
  attr_accessor :town

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

  private
  def set_perishable_token
    self.perishable_token = Authlogic::Random.friendly_token
  end
end
