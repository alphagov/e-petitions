require 'postcode_sanitizer'

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
  validates :constituency_id, length: { maximum: 255 }

  # = Finders =
  scope :validated, -> { where(state: VALIDATED_STATE) }
  scope :pending, -> { where(state: PENDING_STATE) }
  scope :notify_by_email, -> { where(notify_by_email: true) }
  scope :for_email, ->(email) { where(email: email) }
  def self.need_emailing_for(name, since:)
    receipts_table = EmailSentReceipt.arel_table
    validated.
      notify_by_email.
      joins(arel_join_onto_sent_receipts).
      where(
        receipts_table['id'].eq(nil).or(
          receipts_table[name].eq(nil).or(
            receipts_table[name].lt(since)
          )
        )
      )
  end

  def self.arel_join_onto_sent_receipts
    receipts = EmailSentReceipt.arel_table
    sigs = self.arel_table
    join_on = sigs.create_on(sigs[:id].eq(receipts[:signature_id]))
    sigs.create_join(receipts, join_on, Arel::Nodes::OuterJoin)
  end
  private_class_method :arel_join_onto_sent_receipts

  scope :in_days, ->(number_of_days) { validated.where("updated_at > ?", number_of_days.day.ago) }
  scope :matching, ->(signature) { where(email: signature.email,
                                         name: signature.name,
                                         petition_id: signature.petition_id) }

  # = Methods =
  attr_accessor :uk_citizenship

  def self.signature_number(petition_id, validated_at)
    where('petition_id = ? AND validated_at < ?', petition_id, validated_at).count + 1
  end

  def email=(value)
    super(value.to_s.downcase)
  end

  def number
    if validated_at?
      @number ||= self.class.signature_number(petition_id, validated_at)
    end
  end

  def postcode=(value)
    super(PostcodeSanitizer.call(value))
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
    if pending?
      Petition.transaction do
        self.update_columns(
          state:        VALIDATED_STATE,
          validated_at: Time.current,
          updated_at:   Time.current
        )

        ConstituencyPetitionJournal.record_new_signature_for(self)
        petition.creator_signature.validate!
        petition.increment_signature_count!
      end
    end
  end

  def unsubscribe!
    self.update(notify_by_email: false)
  end

  def constituency
    @constituency ||= ConstituencyApi::Client.constituencies(self.postcode).first
  rescue ConstituencyApi::Error => e
    Rails.logger.error("Failed to fetch constituency - #{e}")
    nil
  end

  def set_constituency_id
    self.constituency_id = constituency.try(:id)
  end

  def store_constituency_id
    set_constituency_id
    save if constituency_id_changed?
  end

  def get_email_sent_at_for(name)
    email_sent_receipt!.get(name)
  end
  def set_email_sent_at_for(name, to: Time.current)
    email_sent_receipt!.set(name, to)
  end

  has_one :email_sent_receipt, dependent: :destroy
  def email_sent_receipt!
    email_sent_receipt || create_email_sent_receipt
  end
end
