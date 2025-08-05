require 'textacular/searchable'

class Petition < ActiveRecord::Base
  include PerishableTokenGenerator

  PENDING_STATE     = 'pending'
  VALIDATED_STATE   = 'validated'
  SPONSORED_STATE   = 'sponsored'
  FLAGGED_STATE     = 'flagged'
  DORMANT_STATE     = 'dormant'
  OPEN_STATE        = 'open'
  CLOSED_STATE      = 'closed'
  REJECTED_STATE    = 'rejected'
  HIDDEN_STATE      = 'hidden'
  STOPPED_STATE     = 'stopped'
  REMOVED_STATE     = 'removed'

  STATES            = %w[pending validated sponsored flagged dormant open closed rejected hidden stopped removed]
  DEBATABLE_STATES  = %w[open closed]
  VISIBLE_STATES    = %w[open closed rejected]
  SHOW_STATES       = %w[pending validated sponsored flagged open closed rejected stopped]
  MODERATED_STATES  = %w[open closed hidden rejected]
  REJECTED_STATES   = %w[rejected hidden]
  PUBLISHED_STATES  = %w[open closed]
  SELECTABLE_STATES = %w[open closed rejected hidden]
  SEARCHABLE_STATES = %w[open closed rejected]
  STOPPABLE_STATES  = %w[pending validated sponsored flagged dormant]

  PUBLISHABLE_STATES         = %w[validated sponsored flagged dormant]
  IN_MODERATION_STATES       = %w[sponsored flagged]
  TODO_LIST_STATES           = %w[pending validated sponsored flagged dormant]
  MODERATABLE_STATES         = %w[pending validated sponsored flagged dormant rejected hidden]
  COLLECTING_SPONSORS_STATES = %w[pending validated]
  STOP_COLLECTING_STATES     = %w[pending validated sponsored flagged dormant]

  RESTORABLE_STATES = %w[flagged dormant rejected hidden]
  REJECTABLE_STATES = %w[pending validated sponsored flagged dormant]
  FLAGGABLE_STATES  = %w[pending validated sponsored]

  DEBATE_STATES = %w[pending awaiting scheduled debated not_debated]

  has_perishable_token called: 'sponsor_token'

  before_save :update_debate_state, if: :scheduled_debate_date_changed?
  before_save :update_moderation_lag, unless: :moderation_lag?
  after_create :update_last_petition_created_at

  extend Searchable(:action, :background, :additional_details)
  include Browseable, Taggable, Departments, Topics, Anonymization

  facet :all,      -> { by_most_popular }
  facet :open,     -> { open_state.by_most_popular }
  facet :recent,   -> { open_state.by_most_recently_published }
  facet :rejected, -> { rejected_state.by_most_recent }
  facet :closed,   -> { closed_state.by_most_popular }
  facet :hidden,   -> { hidden_state.by_most_recent }
  facet :stopped,  -> { stopped_state.by_most_recent }

  facet :awaiting_response,    -> { awaiting_response.by_waiting_for_response_longest }
  facet :with_response,        -> { with_response.by_most_recent_response }

  facet :awaiting_debate,      -> { awaiting_debate.by_most_relevant_debate_date }
  facet :with_debate_outcome,  -> { with_debate_outcome.by_most_recent_debate_outcome }
  facet :with_debated_outcome, -> { with_debated_outcome.by_most_recent_debate_outcome }
  facet :debated,              -> { debated.by_most_recent_debate_outcome }
  facet :not_debated,          -> { not_debated.by_most_recent_debate_outcome }

  facet :collecting_sponsors,  -> { collecting_sponsors.by_most_recent }
  facet :in_moderation,        -> { in_moderation.by_most_recent_moderation_threshold_reached }

  facet :recently_in_moderation,       -> { recently_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :nearly_overdue_in_moderation, -> { nearly_overdue_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :overdue_in_moderation,        -> { overdue_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :tagged_in_moderation,         -> { tagged_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :untagged_in_moderation,       -> { untagged_in_moderation.by_most_recent_moderation_threshold_reached }

  facet :flagged, -> { flagged_state.by_most_recent_moderation_threshold_reached }
  facet :dormant, -> { dormant_state.by_most_recent_moderation_threshold_reached }

  filter :topic, ->(code) { topics(code) }

  has_one :creator, -> { creator }, class_name: 'Signature', inverse_of: :petition
  accepts_nested_attributes_for :creator, update_only: true

  with_options class_name: 'AdminUser' do
    belongs_to :locked_by, optional: true
    belongs_to :moderated_by, optional: true
  end

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
  has_many :mailshots, dependent: :destroy
  has_many :invalidations
  has_many :trending_ips, dependent: :delete_all
  has_many :trending_domains, dependent: :delete_all

  has_many :signatures_by_country, -> { preload(:location) }, class_name: "CountryPetitionJournal"
  has_many :signatures_by_constituency, -> { preload(constituency: :region) }, class_name: "ConstituencyPetitionJournal"

  validates :action, presence: true, length: { maximum: 80, allow_blank: true }
  validates :background, presence: true, length: { maximum: 300, allow_blank: true }
  validates :additional_details, length: { maximum: 800, allow_blank: true }

  # The scheduled_debate_date will be blank for most petitions but we
  # can't add `allow_blank: true` here because Active Record validations
  # will not call the DateValidator as all invalid dates are coerced to nil.
  # Therefore the allowing of blank values is handling in the validtor.
  validates :scheduled_debate_date, date: true

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

  delegate :threshold_for_response, :threshold_for_debate, to: :Site
  delegate :formatted_threshold_for_response, to: :Site
  delegate :formatted_threshold_for_debate, to: :Site

  alias_attribute :opened_at, :open_at

  after_create do
    Appsignal.increment_counter("petition.created")
  end

  before_update if: :moderating? do
    self.moderated_by = Admin::Current.user
  end

  class << self
    def by_most_popular
      reorder(signature_count: :desc, created_at: :desc)
    end

    def by_most_recent
      reorder(created_at: :desc)
    end

    def by_most_recently_published
      reorder(open_at: :desc)
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

    def dormant_state
      where(state: DORMANT_STATE)
    end

    def flagged_state
      where(state: FLAGGED_STATE)
    end

    def hidden_state
      where(state: HIDDEN_STATE)
    end

    def rejected_state
      where(state: REJECTED_STATE)
    end

    def validated_state
      where(state: VALIDATED_STATE)
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

    def moderatable
      where(state: MODERATABLE_STATES)
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

    def trending(interval, limit = 3)
      petitions_star = arel_table[Arel.star]
      signatures = Signature.arel_table

      select(petitions_star, signatures[:id].count.as("signature_count_in_period")).
      joins(:signatures).
      where(arel_table[:state].eq(OPEN_STATE)).
      where(signatures[:validated_at].between(interval)).
      where(signatures[:invalidated_at].eq(nil)).
      group(arel_table[:id]).
      order(signatures[:id].count.desc).
      order(arel_table[:created_at].desc).
      limit(limit)
    end

    def close_petitions!(time = Time.current)
      in_need_of_closing(time).find_each do |petition|
        petition.close!(time)
      end
    end

    def close_petitions_early!(time = Parliament.dissolution_at)
      open_at_dissolution(time).find_each do |petition|
        petition.close_early!(time)
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

    def removed
      where(state: REMOVED_STATE)
    end

    def hidden_after_publishing
      where(state: HIDDEN_STATE).where.not(open_at: nil)
    end

    def removed?(id)
      removed.or(hidden_after_publishing).exists?(id)
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
  rescue ActiveRecord::RecordNotUnique => e
    reload_statistics
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

        if debate_state == 'pending'
          updates << "debate_state = 'awaiting'"
        end
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
    updates = []

    if below_threshold_for_debate?
      updates << "debate_threshold_reached_at = NULL"

      if debate_state == 'awaiting'
        updates << "debate_state = 'pending'"
      end
    end

    if below_threshold_for_response?
      updates << "response_threshold_reached_at = NULL"
    end

    if below_threshold_for_moderation?
      if state == 'sponsored'
        updates << "moderation_threshold_reached_at = NULL"
        updates << "state = 'validated'"
      end
    end

    updates << "signature_count = greatest(signature_count - 1, 1)"
    updates << "updated_at = :now"

    updates = updates.join(", ")

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
      signature_count >= Site.threshold_for_response
    end
  end

  def at_threshold_for_debate?
    unless debate_threshold_reached_at?
      signature_count >= Site.threshold_for_debate
    end
  end

  def below_threshold_for_moderation?
    if moderation_threshold_reached_at?
      signature_count <= Site.threshold_for_moderation + 1
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

  def sponsor_count
    @sponsor_count ||= sponsors.select(&:validated?).size
  end

  def sponsors_required
    [(Site.minimum_number_of_sponsors - sponsor_count), 0].max
  end

  def signatures_by_country
    super.sort_by(&:name)
  end

  def signatures_by_constituency
    super.sort_by(&:ons_code)
  end

  def signatures_by_region
    signatures_by_constituency
    .sort_by(&:region_ons_code)
    .group_by(&:region)
    .map do |region, journals|
      RegionPetitionJournal.new(region, journals.sum(&:signature_count))
    end
  end

  def moderation=(value)
    @moderation = value if value.in?(%w[approve reject flag dormant restore])
  end

  def moderation
    @moderation
  end

  def moderate(params)
    self.moderation = params[:moderation]

    transaction do
      # Clear any existing rejection details
      self.rejection = nil
      self.rejected_at = nil

      case moderation
      when 'approve'
        publish!
      when 'reject'
        reject!(params[:rejection])
      when 'flag'
        update!(state: FLAGGED_STATE)
      when 'dormant'
        update!(state: DORMANT_STATE)
      when 'restore'
        update!(state: SPONSORED_STATE, open_at: nil, closed_at: nil)
      else
        errors.add :moderation, :blank
        raise ActiveRecord::RecordNotSaved, "Unable to moderate petition"
      end
    end

    if published?
      Appsignal.increment_counter("petition.published", 1)
    elsif rejected?
      Appsignal.increment_counter("petition.rejected", 1)
    end

    true
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
    reload_rejection unless rejection.present?
    false
  end

  def moderating?
    publishing? || hiding?
  end

  def publishing?
    state.in?(MODERATED_STATES) && state_was.in?(PUBLISHABLE_STATES)
  end

  def hiding?
    hidden? && state_was.in?(VISIBLE_STATES)
  end

  def publish!(time = Time.current)
    errors.add :moderation, :still_pending if pending?

    if errors.any?
      raise ActiveRecord::RecordNotSaved, "Unable to moderate petition"
    end

    update!(
      state: state_for_publishing(time),
      open_at: time_for_publishing(time)
    )
  end

  def reject!(attributes)
    begin
      if rejection.present?
        rejection.attributes = attributes
      else
        build_rejection(attributes)
      end

      rejection.save!
    rescue ActiveRecord::RecordNotUnique => e
      reload_rejection.update!(attributes)
    end
  end

  def close!(time)
    unless open?
      raise RuntimeError, "can't close a petition that is in the #{state} state"
    end

    if deadline <= time
      Appsignal.increment_counter("petition.closed", 1)
      update!(state: CLOSED_STATE, closed_at: deadline)
    end
  end

  def close_early!(time)
    if open?
      Appsignal.increment_counter("petition.closed", 1)
      update!(state: CLOSED_STATE, closed_at: time)
    else
      raise RuntimeError, "can't close a petition that is in the #{state} state"
    end
  end

  def stop!(time = Time.current)
    if state.in?(STOPPABLE_STATES)
      Appsignal.increment_counter("petition.stopped", 1)
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

  def dormant?
    state == DORMANT_STATE
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

  def rejection?
    rejected? || hidden?
  end

  def rejectable?
    state.in?(REJECTABLE_STATES)
  end

  def restorable?
    state.in?(RESTORABLE_STATES)
  end

  def flaggable?
    state.in?(FLAGGABLE_STATES)
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

  def previously_published?(now = Time.current)
    open_at && open_at < now
  end

  def removed?
    state == REMOVED_STATE
  end

  def remove(time = Time.current)
    return false if removed?

    update(
      state: REMOVED_STATE,
      state_at_removal: state,
      removed_at: time
    )
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
  rescue ActiveRecord::RecordNotFound
    false
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
  rescue ActiveRecord::RecordNotFound
    false
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

  def positive_debate_outcome?
    debate_outcome && debate_outcome.debated?
  end

  def deadline
    open_at && (closed_at || Site.closed_at_for_opening(open_at) + deadline_extension)
  end

  def deadline_extension
    super.days
  end

  def extend_deadline!
    self.class.update_counters(id, deadline_extension: 1, touch: touch)
  end

  def closing_early_for_dissolution?(dissolution_at = Parliament.dissolution_at)
    if Parliament.dissolution_announced?
      open_at && dissolution_at ? deadline > dissolution_at : false
    else
      false
    end
  end

  def closing
    open? ? deadline : closed_at
  end

  def update_last_petition_created_at
    Site.last_petition_created_at!
  end

  def has_maximum_sponsors?
    sponsor_count >= Site.maximum_number_of_sponsors
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

  def signatures_to_email_for(name, scope = nil)
    if timestamp = get_email_requested_at_for(name)
      signatures.need_emailing_for(name, since: timestamp, scope: scope)
    else
      raise ArgumentError, "The #{name} email has not been requested for petition #{id}"
    end
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
      debate_threshold_reached_at? ? 'awaiting' : 'pending'
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

  def notes?
    note && note.details.present?
  end

  def state_for_publishing(time)
    if open_at
      closed_at && closed_at < time ? CLOSED_STATE : OPEN_STATE
    else
      OPEN_STATE
    end
  end

  def time_for_publishing(time)
    open_at || time
  end
end
