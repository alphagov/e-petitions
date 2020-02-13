require 'textacular/searchable'

class Petition < ActiveRecord::Base
  include PerishableTokenGenerator

  PENDING_STATE     = 'pending'
  VALIDATED_STATE   = 'validated'
  SPONSORED_STATE   = 'sponsored'
  FLAGGED_STATE     = 'flagged'
  OPEN_STATE        = 'open'
  CLOSED_STATE      = 'closed'
  REJECTED_STATE    = 'rejected'
  HIDDEN_STATE      = 'hidden'
  STOPPED_STATE     = 'stopped'

  STATES            = %w[pending validated sponsored flagged open closed rejected hidden stopped]
  DEBATABLE_STATES  = %w[open closed]
  VISIBLE_STATES    = %w[open closed rejected]
  SHOW_STATES       = %w[pending validated sponsored flagged open closed rejected stopped]
  MODERATED_STATES  = %w[open closed hidden rejected]
  PUBLISHED_STATES  = %w[open closed]
  SELECTABLE_STATES = %w[open closed rejected hidden]
  SEARCHABLE_STATES = %w[open closed rejected]
  STOPPABLE_STATES  = %w[pending validated sponsored flagged]

  IN_MODERATION_STATES       = %w[sponsored flagged]
  TODO_LIST_STATES           = %w[pending validated sponsored flagged]
  COLLECTING_SPONSORS_STATES = %w[pending validated]
  STOP_COLLECTING_STATES     = %w[pending validated sponsored flagged]

  DEBATE_STATES = %w[pending awaiting scheduled debated not_debated]

  has_perishable_token called: 'sponsor_token'

  before_save :update_debate_state, if: :scheduled_debate_date_changed?
  before_save :update_moderation_lag, unless: :moderation_lag?
  after_create :update_last_petition_created_at

  extend Searchable(:action, :background, :additional_details)
  include Browseable, Taggable

  facet :all,      -> { by_most_popular }
  facet :open,     -> { open_state.by_most_popular }
  facet :rejected, -> { rejected_state.by_most_recent }
  facet :closed,   -> { closed_state.by_most_popular }
  facet :hidden,   -> { hidden_state.by_most_recent }
  facet :stopped,  -> { stopped_state.by_most_recent }

  facet :awaiting_response,    -> { awaiting_response.by_waiting_for_response_longest }
  facet :with_response,        -> { with_response.by_most_recent_response }

  facet :awaiting_debate,      -> { awaiting_debate.by_most_relevant_debate_date }
  facet :awaiting_debate_date, -> { awaiting_debate_date.by_waiting_for_debate_longest }
  facet :with_debate_outcome,  -> { with_debate_outcome.by_most_recent_debate_outcome }
  facet :with_debated_outcome, -> { with_debated_outcome.by_most_recent_debate_outcome }
  facet :debated,              -> { debated.by_most_recent_debate_outcome }
  facet :not_debated,          -> { not_debated.by_most_recent_debate_outcome }

  facet :collecting_sponsors,  -> { collecting_sponsors.by_most_recent }
  facet :in_moderation,        -> { in_moderation.by_most_recent_moderation_threshold_reached }
  facet :in_debate_queue,      -> { in_debate_queue.by_waiting_for_debate_longest }

  facet :recently_in_moderation,       -> { recently_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :nearly_overdue_in_moderation, -> { nearly_overdue_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :overdue_in_moderation,        -> { overdue_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :tagged_in_moderation,         -> { tagged_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :untagged_in_moderation,       -> { untagged_in_moderation.by_most_recent_moderation_threshold_reached }

  has_one :creator, -> { creator }, class_name: 'Signature'
  accepts_nested_attributes_for :creator, update_only: true

  belongs_to :locked_by, class_name: 'AdminUser'

  has_one :debate_outcome, dependent: :destroy
  has_one :email_requested_receipt, dependent: :destroy
  has_one :government_response, dependent: :destroy
  has_one :note, dependent: :destroy
  has_one :rejection, dependent: :destroy
  has_one :statistics, dependent: :destroy

  has_many :signatures
  has_many :sponsors, -> { sponsors }, class_name: 'Signature'
  has_many :country_petition_journals, dependent: :destroy
  has_many :constituency_petition_journals, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :invalidations
  has_many :trending_ips, dependent: :delete_all
  has_many :trending_domains, dependent: :delete_all

  validates :action, presence: true, length: { maximum: 100, allow_blank: true }
  validates :background, presence: true, length: { maximum: 500, allow_blank: true }
  # allow extra 100 chars to account for carriage returns
  validates :additional_details, length: { maximum: 1100, allow_blank: true }
  validates :committee_note, length: { maximum: 800, allow_blank: true }
  validates :open_at, presence: true, if: :open?
  validates :creator, presence: true
  validates :state, inclusion: { in: STATES }

  with_options allow_nil: true, prefix: true do
    delegate :name, :email, to: :creator
    delegate :code, :details, to: :rejection
    delegate :summary, :details, :created_at, :updated_at, to: :government_response
    delegate :date, :transcript_url, :video_url, :overview, to: :debate_outcome, prefix: :debate
    delegate :debate_pack_url, to: :debate_outcome, prefix: false
  end

  alias_attribute :opened_at, :open_at

  class << self
    def by_most_popular
      reorder(signature_count: :desc, created_at: :desc)
    end

    def by_most_recent
      reorder(created_at: :desc)
    end

    def by_most_recent_debate_outcome
      reorder(debate_outcome_at: :desc, created_at: :desc)
    end

    def by_most_recent_moderation_threshold_reached
      reorder(moderation_threshold_reached_at: :desc, created_at: :desc)
    end

    def by_most_recent_response
      reorder(government_response_at: :desc, created_at: :desc)
    end

    def by_most_relevant_debate_date
      reorder('scheduled_debate_date ASC NULLS LAST, debate_threshold_reached_at ASC NULLS FIRST')
    end

    def by_oldest
      reorder(created_at: :asc)
    end

    def by_waiting_for_debate_longest
      reorder(debate_threshold_reached_at: :asc, created_at: :desc)
    end

    def by_waiting_for_response_longest
      reorder(response_threshold_reached_at: :asc, created_at: :desc)
    end

    def current
      open_state.by_most_recent
    end

    def open_state
      where(state: OPEN_STATE)
    end

    def closed_state
      where(state: CLOSED_STATE)
    end

    def hidden_state
      where(state: HIDDEN_STATE)
    end

    def rejected_state
      where(state: REJECTED_STATE)
    end

    def sponsored_state
      where(state: SPONSORED_STATE)
    end

    def stopped_state
      where(state: STOPPED_STATE)
    end

    def awaiting_debate
      where(debate_state: %w[awaiting scheduled])
    end

    def awaiting_debate_date
      debate_threshold_reached.not_scheduled
    end

    def awaiting_response
      response_threshold_reached.not_responded
    end

    def collecting_sponsors
      where(state: COLLECTING_SPONSORS_STATES)
    end

    def debate_threshold_reached
      where.not(debate_threshold_reached_at: nil)
    end

    def debateable
      where(state: DEBATABLE_STATES)
    end

    def debated
      where(debate_state: 'debated').preload(:debate_outcome)
    end

    def for_state(state)
      where(state: state)
    end

    def in_debate_queue
      where(threshold_for_debate_reached.or(scheduled_for_debate))
    end

    def in_moderation(from: nil, to: nil)
      if from && to
        where(state: IN_MODERATION_STATES).where(moderation_threshold_reached_at.between(from..to))
      elsif from
        where(state: IN_MODERATION_STATES).where(moderation_threshold_reached_at.gt(from))
      elsif to
        where(state: IN_MODERATION_STATES).where(moderation_threshold_reached_at.lt(to))
      else
        where(state: IN_MODERATION_STATES)
      end
    end

    def moderated
      where(state: MODERATED_STATES)
    end

    def not_debated
      where(debate_state: 'not_debated')
    end

    def not_hidden
      where.not(state: HIDDEN_STATE)
    end

    def not_responded
      where(government_response_at: nil)
    end

    def not_scheduled
      where(scheduled_debate_date: nil)
    end

    def respondable
      where(state: RESPONDABLE_STATES)
    end

    def response_threshold_reached
      where.not(response_threshold_reached_at: nil)
    end

    def selectable
      where(state: SELECTABLE_STATES)
    end

    def stoppable
      where(state: STOPPABLE_STATES)
    end

    def show
      where(state: SHOW_STATES)
    end

    def threshold
      where(arel_table[:signature_count].gteq(Site.threshold_for_debate))
    end

    def todo_list
      where(state: TODO_LIST_STATES)
    end

    def visible
      where(state: VISIBLE_STATES)
    end

    def with_debate_outcome
      where.not(debate_outcome_at: nil)
    end

    def with_debated_outcome
      debated.where.not(debate_outcome_at: nil)
    end

    def with_response
      where.not(government_response_at: nil).preload(:government_response)
    end

    def trending(since = 1.hour.ago, limit = 3)
      select('petitions.*, COUNT(signatures.id) AS signature_count_in_period').
      joins(:signatures).
      where('petitions.state = ?', OPEN_STATE).
      where('petitions.last_signed_at > ?', since).
      where('signatures.validated_at > ?', since).
      where('signatures.invalidated_at IS NULL').
      group('petitions.id').order('signature_count_in_period DESC').
      limit(limit)
    end

    def close_petitions!(time = Time.current)
      in_need_of_closing(time).find_each do |petition|
        petition.close!
      end
    end

    def close_petitions_early!(time = Parliament.dissolution_at)
      open_at_dissolution(time).find_each do |petition|
        petition.close!(time)
      end
    end

    def stop_petitions_early!(time = Parliament.dissolution_at)
      in_need_of_stopping.find_each do |petition|
        petition.stop!(time)
      end
    end

    def in_need_of_closing(time = Time.current)
      where(state: OPEN_STATE).where(arel_table[:open_at].lt(Site.opened_at_for_closing(time)))
    end

    def in_need_of_stopping(time = nil)
      scope = preload(:creator)
      time ? scope.stoppable.created_after(time) : scope.stoppable
    end

    def created_after(time)
      where(arel_table[:created_at].gteq(time))
    end

    def open_at_dissolution(dissolution_at = Parliament.dissolution_at)
      if dissolution_at
        opened_at_for_closing = Site.opened_at_for_closing(dissolution_at)

        where(
          arel_table[:state].eq(OPEN_STATE).
          and(arel_table[:open_at].gteq(opened_at_for_closing).
          and(arel_table[:closed_at].eq(nil)).
          or(arel_table[:closed_at].gteq(dissolution_at)))
        )
      else
        none
      end
    end

    def popular_in_constituency(constituency_id, count = 50)
      popular_in(constituency_id, count).for_state(OPEN_STATE)
    end

    def all_popular_in_constituency(constituency_id, count = 50)
      popular_in(constituency_id, count).for_state(PUBLISHED_STATES)
    end

    def sanitized_tag(tag)
      "[#{tag.gsub(/[\[\]%]/,'')}]"
    end

    def in_need_of_marking_as_debated(date = Date.current)
      where(scheduled_debate_state.and(debate_date_in_the_past(date)))
    end

    def mark_petitions_as_debated!(date = Date.current)
      in_need_of_marking_as_debated(date).update_all(debate_state: 'debated')
    end

    def unarchived
      where(archived_at: nil)
    end

    def recently_in_moderation
      in_moderation(from: moderation_near_overdue_at)
    end

    def nearly_overdue_in_moderation
      in_moderation(from: moderation_overdue_at, to: moderation_near_overdue_at)
    end

    def overdue_in_moderation
      in_moderation(to: moderation_overdue_at)
    end

    def tagged_in_moderation
      tagged.in_moderation
    end

    def untagged_in_moderation
      untagged.in_moderation
    end

    def signed_since(timestamp)
      where(arel_table[:last_signed_at].gt(timestamp))
    end

    def in_need_of_validating
      where(grouping(last_signed_at.gt(signature_count_validated_at)).eq(true))
    end

    private

    def grouping(expression)
      Arel::Nodes::Grouping.new(expression)
    end

    def last_signed_at
      arel_table[:last_signed_at]
    end

    def signature_count_validated_at
      arel_table[:signature_count_validated_at]
    end

    def moderation_threshold_reached_at
      arel_table[:moderation_threshold_reached_at]
    end

    def moderation_near_overdue_at
      Site.moderation_near_overdue_in_days.ago
    end

    def moderation_overdue_at
      Site.moderation_overdue_in_days.ago
    end

    def popular_in(constituency_id, count)
      klass = ConstituencyPetitionJournal
      constituency_signature_count = klass.arel_table[:signature_count].as('constituency_signature_count')
      constituency_signatures_for = klass.with_signatures_for(constituency_id).ordered

      select(arel_table[Arel.star], constituency_signature_count).
      joins(:constituency_petition_journals).
      merge(constituency_signatures_for).
      limit(count)
    end

    def threshold_for_debate_reached
      arel_table[:debate_threshold_reached_at].not_eq(nil)
    end

    def scheduled_for_debate
      arel_table[:scheduled_debate_date].not_eq(nil)
    end

    def awaiting_debate_state
      arel_table[:debate_state].eq('awaiting')
    end

    def debate_date_in_the_past(date)
      arel_table[:scheduled_debate_date].lt(date)
    end

    def scheduled_debate_state
      arel_table[:debate_state].eq('scheduled')
    end
  end

  def statistics
    super || create_statistics!
  end

  def reset_signature_count!(time = Time.current)
    update_column(:signature_count_reset_at, time)
    update_signature_count!(time)
    ConstituencyPetitionJournal.reset_signature_counts_for(self)
    CountryPetitionJournal.reset_signature_counts_for(self)
    update_column(:signature_count_reset_at, nil)
  end

  def update_signature_count!(time = Time.current)
    sql = "signature_count = ?, last_signed_at = ?, updated_at = ?"
    count = signatures.validated_count(nil, time)

    if update_all([sql, count, time, time]) > 0
      self.reload
    end
  end

  def increment_signature_count!(time = Time.current)
    sql = "signature_count = signature_count + ?, last_signed_at = ?, updated_at = ?"
    count = signatures.validated_count(last_signed_at, time)

    return false if count.zero?

    if result = update_all([sql, count, time, time]) > 0
      self.reload

      updates = []

      if at_threshold_for_moderation? && collecting_sponsors?
        updates << "state = '#{SPONSORED_STATE}'"
        updates << "moderation_threshold_reached_at = :now"
      elsif pending?
        updates << "state = '#{VALIDATED_STATE}'"
      end

      if at_threshold_for_response?
        updates << "response_threshold_reached_at = :now"
      end

      if at_threshold_for_debate?
        updates << "debate_threshold_reached_at = :now"
        updates << "debate_state = 'awaiting'"
      end

      updates = updates.join(", ")

      if updates.present?
        if update_all([updates, now: time]) > 0
          self.reload
        end
      end
    end

    result
  end

  def decrement_signature_count!(time = Time.current)
    updates = ""

    if below_threshold_for_debate?
      updates << "debate_threshold_reached_at = NULL, "
      updates << "debate_state = 'pending', "
    end

    if below_threshold_for_response?
      updates << "response_threshold_reached_at = NULL, "
    end

    updates << "signature_count = greatest(signature_count - 1, 1), "
    updates << "updated_at = :now"

    if update_all([updates, now: time]) > 0
      self.reload
    end
  end

  def signature_count_difference
    signature_count - signatures.validated_count(nil, last_signed_at)
  end

  def valid_signature_count?
    signature_count_difference.zero?
  end

  def valid_signature_count!
    valid_signature_count? && touch(:signature_count_validated_at)
  end

  def will_reach_threshold_for_moderation?
    unless moderation_threshold_reached_at?
      signature_count >= Site.threshold_for_moderation
    end
  end

  def at_threshold_for_moderation?
    unless moderation_threshold_reached_at?
      signature_count >= Site.threshold_for_moderation + 1
    end
  end

  def at_threshold_for_response?
    unless response_threshold_reached_at?
      signature_count >= Site.threshold_for_response - 1
    end
  end

  def at_threshold_for_debate?
    unless debate_threshold_reached_at?
      signature_count >= Site.threshold_for_debate - 1
    end
  end

  def below_threshold_for_response?
    if response_threshold_reached_at?
      signature_count <= Site.threshold_for_response
    end
  end

  def below_threshold_for_debate?
    if debate_threshold_reached_at?
      signature_count <= Site.threshold_for_debate
    end
  end

  def signatures_by_country
    country_petition_journals.joins(:location).preload(:location).to_a.sort_by(&:name)
  end

  def signatures_by_constituency
    constituency_petition_journals.preload(:constituency).to_a.sort_by(&:constituency_id)
  end

  def approve?
    moderation == 'approve'
  end

  def reject?
    moderation == 'reject'
  end

  def flag?
    moderation == 'flag'
  end

  def moderation=(value)
    @moderation = value if value.in?(%w[approve reject flag])
  end

  def moderation
    @moderation
  end

  def moderate(params)
    self.moderation = params[:moderation]

    if approve?
      publish
    elsif reject?
      reject(params[:rejection])
    elsif flag?
      flag
    else
      errors.add :moderation, :blank
      false
    end
  end

  def publish(time = Time.current)
    update(state: OPEN_STATE, open_at: time)
  end

  def reject(attributes)
    begin
      build_rejection(attributes) && rejection.save
    rescue ActiveRecord::RecordNotUnique => e
      reload_rejection.update(attributes)
    end
  end

  def flag
    update(state: FLAGGED_STATE)
  end

  def rejection(*args)
    super || build_rejection
  end

  def close!(time = deadline)
    if open?
      update!(state: CLOSED_STATE, closed_at: time)
    else
      raise RuntimeError, "can't stop a petition that is in the #{state} state"
    end
  end

  def stop!(time = Time.current)
    if state.in?(STOPPABLE_STATES)
      update!(state: STOPPED_STATE, stopped_at: time)
    else
      raise RuntimeError, "can't stop a petition that is in the #{state} state"
    end
  end

  def validate_creator!(now = Time.current)
    if pending?
      # Set the validated_at time to 1 second ago so that if
      # the signature count update runs for it then it won't
      # prevent this signature being missed.
      creator && creator.validate!(1.second.ago(now)) && reload
    end
  end

  def count_validated_signatures
    signatures.validated.count
  end

  def collecting_sponsors?
    state.in?(COLLECTING_SPONSORS_STATES)
  end

  def awaiting_moderation?
    state == VALIDATED_STATE
  end

  def in_moderation?
    state.in?(IN_MODERATION_STATES)
  end

  def moderated?
    state.in?(MODERATED_STATES)
  end

  def open?
    state == OPEN_STATE
  end
  alias_method :can_be_signed?, :open?

  def rejected?
    state == REJECTED_STATE
  end

  def hidden?
    state == HIDDEN_STATE
  end

  def closed?
    state == CLOSED_STATE
  end

  def stopped?
    state == STOPPED_STATE
  end

  def flagged?
    state == FLAGGED_STATE
  end

  def pending?
    state == PENDING_STATE
  end

  def validated?
    state == VALIDATED_STATE
  end

  def published?
    state.in?(PUBLISHED_STATES)
  end

  def visible?
    state.in?(VISIBLE_STATES)
  end

  def closed_for_signing?(now = Time.current)
    rejected? || closed_at? && closed_at < 24.hours.ago(now)
  end

  def archiving?
    archiving_started_at? && !archived_at?
  end

  def archived?
    archived_at?
  end

  def editing_disabled?
    archiving_started_at? || archived_at?
  end

  def update_lock!(user, now = Time.current)
    if locked_by == user
      update!(locked_at: now)
    end
  end

  def checkout!(user, now = Time.current)
    with_lock do
      if locked_by.present? && locked_by != user
        false
      else
        update!(locked_by: user, locked_at: now)
      end
    end
  end

  def force_checkout!(user, now = Time.current)
    update!(locked_by: user, locked_at: now)
  end

  def release!(user)
    with_lock do
      if locked_by.present? && locked_by == user
        update!(locked_by: nil, locked_at: nil)
      end
    end
  end

  def can_have_debate_added?
    state.in?(DEBATABLE_STATES)
  end

  def in_todo_list?
    state.in?(TODO_LIST_STATES)
  end

  def government_response?
    government_response_at? && government_response
  end

  def debate_outcome?
    debate_outcome_at? && debate_outcome
  end

  def deadline
    open_at && (closed_at || Site.closed_at_for_opening(open_at))
  end

  def closing_early_for_dissolution?(dissolution_at = Parliament.dissolution_at)
    if Parliament.dissolution_announced?
      open_at && dissolution_at ? deadline > dissolution_at : false
    else
      false
    end
  end

  def cache_key(*timestamp_names)
    case
    when new_record?
      "petitions/new"
    when timestamp_names.any?
      timestamp = max_updated_column_timestamp(timestamp_names)
      timestamp = timestamp.change(sec: (timestamp.sec.div(5) * 5))
      timestamp = timestamp.utc.to_s(cache_timestamp_format)
      "petitions/#{id}-#{timestamp}"
    when timestamp = max_updated_column_timestamp
      timestamp = timestamp.change(sec: (timestamp.sec.div(5) * 5))
      timestamp = timestamp.utc.to_s(cache_timestamp_format)
      "petitions/#{id}-#{timestamp}"
    else
      "petitions/#{id}"
    end
  end

  def update_last_petition_created_at
    Site.last_petition_created_at!
  end

  def has_maximum_sponsors?
    sponsors.validated.count >= Site.maximum_number_of_sponsors
  end

  def update_all(updates)
    self.class.unscoped.where(id: id).update_all(updates)
  end

  def email_requested_receipt!
    email_requested_receipt || create_email_requested_receipt
  end

  def get_email_requested_at_for(name)
    email_requested_receipt!.get(name)
  end

  def set_email_requested_at_for(name, to: Time.current)
    email_requested_receipt!.set(name, to)
  end

  def signatures_to_email_for(name)
    timestamp = get_email_requested_at_for(name)
    raise ArgumentError if timestamp.nil?
    signatures.need_emailing_for(name, since: timestamp)
  end

  def awaiting_debate?
    debate_state.in?(%w[awaiting scheduled])
  end

  def debated?
    debate_state == 'debated'
  end

  def not_debated?
    debate_state == 'not_debated'
  end

  def update_debate_state
    self.debate_state = evaluate_debate_state
  end

  def evaluate_debate_state
    if scheduled_debate_date?
      scheduled_debate_date > Date.current ? 'scheduled' : 'debated'
    else
      'awaiting'
    end
  end

  def fraudulent_domains
    @fraudulent_domains ||= signatures.fraudulent_domains
  end

  def fraudulent_domains?
    !fraudulent_domains.empty?
  end

  def closed_early_due_to_election?(dissolution_at = Parliament.dissolution_at)
    closed_at == dissolution_at
  end

  def update_moderation_lag
    if open_at_changed? || rejected_at_changed?
      self.moderation_lag = calculate_moderation_lag(Date.current)
    end
  end

  def calculate_moderation_lag(today)
    if moderation_threshold_reached_at?
      today - moderation_threshold_reached_at.to_date
    else
      0
    end
  end
end
