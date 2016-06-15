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

  validates_inclusion_of :state, in: STATES
  validates :constituency_id, length: { maximum: 255 }

  after_create do
    Domain.log(email)
  end

  before_destroy do
    !creator?
  end

  after_destroy do
    petition.update_signature_count!
  end

  # = Finders =
  scope :validated, -> { where(state: VALIDATED_STATE) }
  scope :pending, -> { where(state: PENDING_STATE) }
  scope :notify_by_email, -> { where(notify_by_email: true) }
  scope :for_email, ->(email) { where(email: email.downcase) }
  scope :for_name, ->(name) { where("lower(name) = ?", name.downcase) }

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

  def self.petition_ids_with_invalid_signature_counts
    validated.joins(:petition).
      group([arel_table[:petition_id], Petition.arel_table[:signature_count]]).
      having(arel_table[Arel.star].count.not_eq(Petition.arel_table[:signature_count])).
      pluck(:petition_id)
  end

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
    update_signature_counts = false

    retry_lock do
      if pending?
        update_signature_counts = true
        petition.validate_creator_signature! unless creator?

        update_columns(
          number:       petition.signature_count + 1,
          state:        VALIDATED_STATE,
          validated_at: Time.current,
          updated_at:   Time.current
        )
      end
    end

    if update_signature_counts
      ConstituencyPetitionJournal.record_new_signature_for(self)
      CountryPetitionJournal.record_new_signature_for(self)
      petition.increment_signature_count!
    end
  end

  def mark_seen_signed_confirmation_page!
    update seen_signed_confirmation_page: true
  end

  def unsubscribe!(token)
    if unsubscribed?
      errors.add(:base, "Already Unsubscribed")
    elsif unsubscribe_token != token
      errors.add(:base, "Invalid Unsubscribe Token")
    else
      update(notify_by_email: false)
    end
  end

  def already_unsubscribed?
    errors[:base].include?("Already Unsubscribed")
  end

  def invalid_unsubscribe_token?
    errors[:base].include?("Invalid Unsubscribe Token")
  end

  def constituency
    @constituency ||= Constituency.find_by_postcode(postcode)
  end

  def set_constituency_id
    self.constituency_id = constituency.try(:external_id)
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

  def domain_allowed?
    domain && domain.allowed?
  end

  private

  def domain
    @domain ||= Domain.find_or_create_by_email(email)
  end

  def retry_lock
    retried = false

    begin
      with_lock { yield }
    rescue PG::InFailedSqlTransaction => e
      if retried
        raise e
      else
        retried = true
        self.class.connection.clear_cache!
        retry
      end
    end
  end
end
