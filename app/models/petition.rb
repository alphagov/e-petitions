require 'textacular/searchable'

class Petition < ActiveRecord::Base
  include PerishableTokenGenerator
  include Translatable

  PENDING_STATE     = 'pending'
  VALIDATED_STATE   = 'validated'
  SPONSORED_STATE   = 'sponsored'
  FLAGGED_STATE     = 'flagged'
  OPEN_STATE        = 'open'
  CLOSED_STATE      = 'closed'
  COMPLETED_STATE   = 'completed'
  REJECTED_STATE    = 'rejected'
  HIDDEN_STATE      = 'hidden'

  STATES            = %w[pending validated sponsored flagged open closed completed rejected hidden]
  DEBATABLE_STATES  = %w[closed completed]
  VISIBLE_STATES    = %w[open closed completed rejected]
  SHOW_STATES       = %w[pending validated sponsored flagged open closed completed rejected]
  MODERATED_STATES  = %w[open closed completed hidden rejected]
  REJECTED_STATES   = %w[rejected hidden]
  PUBLISHED_STATES  = %w[open closed completed]
  SELECTABLE_STATES = %w[open closed completed rejected hidden]
  SEARCHABLE_STATES = %w[open closed completed rejected]
  CURRENT_STATES    = %w[open closed]
  ARCHIVABLE_STATES = %w[completed rejected hidden]

  PUBLISHABLE_STATES         = %w[validated sponsored flagged]
  IN_MODERATION_STATES       = %w[sponsored flagged]
  MODERATABLE_STATES         = %w[pending validated sponsored flagged rejected hidden]
  TODO_LIST_STATES           = %w[pending validated sponsored flagged]
  COLLECTING_SPONSORS_STATES = %w[pending validated]

  DEBATE_STATES = %w[pending awaiting scheduled debated not_debated]

  self.cache_timestamp_format = :stepped_cache_key

  has_perishable_token called: 'sponsor_token'

  translate :action, :additional_details, :background, :abms_link

  before_save :update_debate_state, if: :scheduled_debate_date_changed?
  before_save :update_moderation_lag, unless: :moderation_lag?
  before_create :set_threshold_for_referral
  before_create :set_threshold_for_debate
  after_create :update_last_petition_created_at

  extend Searchable(:action_en, :action_cy, :background_en, :background_cy, :additional_details_en, :additional_details_cy)
  include Browseable, Taggable, Topics

  facet :all,       -> { not_archived.by_most_recent }
  facet :open,      -> { not_archived.open_state.by_most_popular }
  facet :rejected,  -> { not_archived.rejected_state.by_most_recent }
  facet :closed,    -> { not_archived.closed_state.not_referred.by_most_popular }
  facet :referred,  -> { not_archived.closed_state.referred.by_most_recently_closed }
  facet :completed, -> { not_archived.completed_state.by_most_recently_closed }
  facet :hidden,    -> { not_archived.hidden_state.by_most_recent }
  facet :archived,  -> { archived.by_most_recently_closed }

  facet :awaiting_debate,      -> { not_archived.awaiting_debate.by_most_relevant_debate_date }
  facet :awaiting_debate_date, -> { not_archived.awaiting_debate_date.by_waiting_for_debate_longest }
  facet :with_debate_outcome,  -> { not_archived.with_debate_outcome.by_most_recent_debate_outcome }
  facet :with_debated_outcome, -> { not_archived.with_debated_outcome.by_most_recent_debate_outcome }
  facet :debated,              -> { not_archived.debated.by_most_recent_debate_outcome }
  facet :not_debated,          -> { not_archived.not_debated.by_most_recent_debate_outcome }

  facet :collecting_sponsors,  -> { collecting_sponsors.by_most_recent }
  facet :in_moderation,        -> { in_moderation.by_most_recent_moderation_threshold_reached }
  facet :in_debate_queue,      -> { in_debate_queue.by_waiting_for_debate_longest }

  facet :recently_in_moderation,       -> { recently_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :nearly_overdue_in_moderation, -> { nearly_overdue_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :overdue_in_moderation,        -> { overdue_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :tagged_in_moderation,         -> { tagged_in_moderation.by_most_recent_moderation_threshold_reached }
  facet :untagged_in_moderation,       -> { untagged_in_moderation.by_most_recent_moderation_threshold_reached }

  filter :topic, ->(codes) { topics(codes) }

  has_one :creator, -> { creator }, class_name: 'Signature', inverse_of: :petition
  accepts_nested_attributes_for :creator, update_only: true

  with_options class_name: 'AdminUser' do
    belongs_to :locked_by, optional: true
    belongs_to :moderated_by, optional: true
  end

  has_one :debate_outcome, dependent: :destroy
  has_one :email_requested_receipt, dependent: :destroy
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

  has_many :signatures_by_country, class_name: "CountryPetitionJournal"
  has_many :signatures_by_uk_country, -> { uk }, class_name: "CountryPetitionJournal"
  has_many :signatures_by_constituency, -> { preload(constituency: :region) }, class_name: "ConstituencyPetitionJournal"

  Translation = Struct.new(:petition, :locale) do
    %i[action background additional_details].each do |name|
      define_method name do
        translated_method(name)
      end
    end

    private

    def suffix
      locale == :"cy-GB" ? "cy" : "en"
    end

    def translated_method(name)
      petition.public_send(:"#{name}_#{suffix}").to_s
    end
  end

  attr_accessor :editing

  validate if: :editing do
    t = Translation.new(self, editing)
    errors.add :action, :blank unless t.action.present?
    errors.add :action, :too_long, count: 255 if t.action.length > 255
    errors.add :background, :blank unless t.background.present?
    # allow extra characters to account for carriage returns
    errors.add :background, :too_long, count: 3000 if t.background.length > 3000
    errors.add :additional_details, :too_long, count: 5000 if t.additional_details.length > 5000
  end

  # The scheduled_debate_date will be blank for most petitions but we
  # can't add `allow_blank: true` here because Active Record validations
  # will not call the DateValidator as all invalid dates are coerced to nil.
  # Therefore the allowing of blank values is handling in the validtor.
  validates :scheduled_debate_date, date: true

  validates :open_at, presence: true, if: :open?
  validates :creator, presence: true, unless: :completed?
  validates :state, inclusion: { in: STATES }

  validates :abms_link_en, url: true
  validates :abms_link_cy, url: true

  validates :completed_at, presence: true, if: :completed?

  with_options allow_nil: true, prefix: true do
    delegate :name, :email, to: :creator
    delegate :code, :details, to: :rejection
    delegate :date, :transcript_url, :video_url, :overview, to: :debate_outcome, prefix: :debate
    delegate :debate_pack_url, to: :debate_outcome, prefix: false
  end

  alias_attribute :opened_at, :open_at
  attribute :locale, :string, default: -> { I18n.locale }

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

    def by_most_recently_closed
      reorder(closed_at: :desc)
    end

    def by_most_recent_debate_outcome
      reorder(debate_outcome_at: :desc, created_at: :desc)
    end

    def by_most_recent_moderation_threshold_reached
      reorder(moderation_threshold_reached_at: :desc, created_at: :desc)
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

    def by_referred_longest
      reorder(referred_at: :asc, created_at: :desc)
    end

    def current
      where(state: CURRENT_STATES).by_most_recent
    end

    def open_state
      where(state: OPEN_STATE)
    end

    def closed_state
      where(state: CLOSED_STATE)
    end

    def completed_state
      where(state: COMPLETED_STATE)
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

    def awaiting_debate
      where(debate_state: %w[awaiting scheduled])
    end

    def awaiting_debate_date
      debate_threshold_reached.not_scheduled
    end

    def referred
      where(arel_table[:referred_at].not_eq(nil))
    end

    def not_referred
      where(arel_table[:referred_at].eq(nil))
    end

    def archived
      where(arel_table[:archived_at].not_eq(nil))
    end

    def not_archived
      where(arel_table[:archived_at].eq(nil))
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

    def not_completed
      where.not(state: COMPLETED_STATE)
    end

    def not_debated
      where(debate_state: 'not_debated')
    end

    def not_hidden
      where.not(state: HIDDEN_STATE)
    end

    def not_scheduled
      where(scheduled_debate_date: nil)
    end

    def referral_threshold_reached
      where.not(referral_threshold_reached_at: nil)
    end

    def selectable
      where(state: SELECTABLE_STATES)
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

    def in_need_of_closing(time = Time.current)
      where(state: OPEN_STATE).where(arel_table[:closed_at].lt(time))
    end

    def refer_or_reject_petitions!(time = Time.current)
      in_need_of_referring_or_rejecting(time).find_each do |petition|
        petition.refer_or_reject!(time)
      end
    end

    def in_need_of_referring_or_rejecting(time = Time.current)
      closed_state.not_referred.closed_before(24.hours.before(time))
    end

    def closed_before(time)
      where(arel_table[:closed_at].lt(time))
    end

    def created_after(time)
      where(arel_table[:created_at].gteq(time))
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

    def paper
      where(submitted_on_paper: true)
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
    return if submitted_on_paper?

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

      if at_threshold_for_referral?
        updates << "referral_threshold_reached_at = :now"
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

    if below_threshold_for_referral?
      updates << "referral_threshold_reached_at = NULL"
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

  def at_threshold_for_referral?
    unless referral_threshold_reached_at?
      signature_count >= threshold_for_referral
    end
  end

  def at_threshold_for_debate?
    unless debate_threshold_reached_at?
      signature_count >= threshold_for_debate
    end
  end

  def below_threshold_for_referral?
    if referral_threshold_reached_at?
      signature_count <= threshold_for_referral
    end
  end

  def below_threshold_for_debate?
    if debate_threshold_reached_at?
      signature_count <= threshold_for_debate
    end
  end

  def signatures_by_country
    super.sort_by(&:name)
  end

  def signatures_by_constituency
    super.sort_by(&:constituency_id)
  end

  def signatures_by_region
    signatures_by_constituency
    .sort_by(&:region_id)
    .group_by(&:region)
    .map do |region, journals|
      RegionPetitionJournal.new(region, journals.sum(&:signature_count))
    end
  end

  def moderation=(value)
    @moderation = value if value.in?(%w[approve reject restore flag unflag])
  end

  def moderation
    @moderation
  end

  def content
    translated_method(:content_en, :content_cy)
  end

  def content_en
    [background_en, additional_details_en].reject(&:blank?).join("\n\n")
  end

  def content_cy
    [background_cy, additional_details_cy].reject(&:blank?).join("\n\n")
  end

  def english?
    locale == "en-GB"
  end

  def welsh?
    locale == "cy-GB"
  end

  def translated?
    english_translated? && welsh_translated?
  end

  def english_translated?
    action_en? && background_en? && additional_details_en_translated?
  end

  def additional_details_en_translated?
    english? ? true : !additional_details_cy? || additional_details_en?
  end

  def welsh_translated?
    action_cy? && background_cy? && additional_details_cy_translated?
  end

  def additional_details_cy_translated?
    welsh? ? true : !additional_details_en? || additional_details_cy?
  end

  def will_be_hidden?
    rejection && rejection.hide_petition?
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
      when 'unflag', 'restore'
        update!(state: SPONSORED_STATE)
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
    errors.add :moderation, :translation_missing unless translated?
    errors.add :moderation, :still_pending if pending?

    if errors.any?
      raise ActiveRecord::RecordNotSaved, "Unable to moderate petition"
    end

    update!(
      state: state_for_publishing(time),
      open_at: time_for_publishing(time),
      closed_at: closing_date(time)
    )
  end

  def reject!(attributes)
    begin
      if rejection.present?
        rejection.attributes = attributes
      else
        build_rejection(attributes)
      end

      unless translated?
        if english?
          update_columns(
            action_cy: action_en,
            background_cy: background_en,
            additional_details_cy: additional_details_en
          )
        else
          update_columns(
            action_en: action_cy,
            background_en: background_cy,
            additional_details_en: additional_details_cy
          )
        end
      end

      rejection.save!
    rescue ActiveRecord::RecordNotUnique => e
      reload_rejection.update!(attributes)
    end
  end

  def complete(time = Time.current)
    if closed?
      Appsignal.increment_counter("petition.completed", 1)
      update(state: COMPLETED_STATE, completed_at: time)
    end
  end

  def archivable?
    !archived? && state.in?(ARCHIVABLE_STATES)
  end

  def archive(time = Time.current)
    if archivable?
      Appsignal.increment_counter("petition.archived", 1)
      update(archived_at: time)
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

  def refer_or_reject!(time)
    if closed? && !referred?
      if will_be_referred?
        Appsignal.increment_counter("petition.referred", 1)
        update!(referred_at: time)
      else
        reject!(code: "insufficient", rejected_at: time)
        NotifyEveryoneOfFailureToGetEnoughSignaturesJob.perform_later(self)
      end
    else
      raise RuntimeError, "can't refer or reject a petition that is in the #{state} state"
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

  def completed?
    state == COMPLETED_STATE
  end

  def archived?
    archived_at?
  end

  def will_be_referred?
    referral_threshold_reached_at?
  end

  def referred?
    referred_at? || completed?
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

  def rejection?
    rejected? || hidden?
  end

  def previously_published?(now = Time.current)
    open_at && open_at < now
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

  def debate_outcome?
    debate_outcome_at? && debate_outcome
  end

  def deadline
    if published?
      (closed_at || Site.closed_at_for_opening(open_at))
    end
  end

  def extend_deadline!(amount = 1.day, now = Time.current)
    update_columns(closed_at: closed_at + amount, updated_at: now)
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
      debate_threshold_reached_at? ? 'awaiting' : 'pending'
    end
  end

  def fraudulent_domains
    @fraudulent_domains ||= signatures.fraudulent_domains
  end

  def fraudulent_domains?
    !fraudulent_domains.empty?
  end

  def update_moderation_lag
    return unless state_was.in?(TODO_LIST_STATES)

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

  def closing_date(time)
    closed_at || Site.closed_at_for_opening(time)
  end

  def sponsor_count
    @sponsor_count ||= sponsors.validated.count
  end

  def state_for_publishing(time)
    if open_at
      closed_at > time ? OPEN_STATE : CLOSED_STATE
    else
      OPEN_STATE
    end
  end

  def time_for_publishing(time)
    open_at || time
  end

  def set_threshold_for_referral
    self[:threshold_for_referral] ||= Site.threshold_for_referral
  end

  def set_threshold_for_debate
    self[:threshold_for_debate] ||= Site.threshold_for_debate
  end

  def threshold_for_referral
    super || Site.threshold_for_referral
  end

  def threshold_for_debate
    super || Site.threshold_for_debate
  end
end
