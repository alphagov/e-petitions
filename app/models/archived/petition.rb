require 'textacular/searchable'

module Archived
  class Petition < ActiveRecord::Base
    STOPPED_STATE = 'stopped'
    CLOSED_STATE = 'closed'
    HIDDEN_STATE = 'hidden'
    REJECTED_STATE = 'rejected'
    REMOVED_STATE = 'removed'
    STATES = [STOPPED_STATE, CLOSED_STATE, HIDDEN_STATE, REJECTED_STATE, REMOVED_STATE]
    PUBLISHED_STATES = [CLOSED_STATE]
    VISIBLE_STATES = [CLOSED_STATE, REJECTED_STATE]
    MODERATED_STATES = [CLOSED_STATE, HIDDEN_STATE, REJECTED_STATE]
    DEBATABLE_STATES = [CLOSED_STATE]
    REJECTED_STATES = [REJECTED_STATE, HIDDEN_STATE]

    belongs_to :parliament, inverse_of: :petitions

    with_options class_name: 'AdminUser' do
      belongs_to :locked_by, optional: true
      belongs_to :moderated_by, optional: true
    end

    has_one :creator, -> { creator }, class_name: "Signature"
    has_one :debate_outcome, dependent: :destroy
    has_one :government_response, dependent: :destroy
    has_one :note, dependent: :destroy
    has_one :rejection, dependent: :destroy

    has_many :emails, dependent: :destroy
    has_many :mailshots, dependent: :destroy
    has_many :signatures
    has_many :sponsors, -> { sponsors }, class_name: "Signature"

    validates :action, presence: true, length: { maximum: 150 }
    validates :background, length: { maximum: 300 }, allow_blank: true
    validates :additional_details, length: { maximum: 1000 }, allow_blank: true
    validates :committee_note, length: { maximum: 800 }, allow_blank: true
    validates :state, presence: true, inclusion: STATES
    validates :closed_at, presence: true, if: :closed?

    # The scheduled_debate_date will be blank for most petitions but we
    # can't add `allow_blank: true` here because Active Record validations
    # will not call the DateValidator as all invalid dates are coerced to nil.
    # Therefore the allowing of blank values is handling in the validtor.
    validates :scheduled_debate_date, date: true

    # Validate associated models so that archive petition job fails if they're not valid.
    validates_associated :debate_outcome, :government_response, :note, :rejection

    before_save :update_debate_state, if: :scheduled_debate_date_changed?

    extend Searchable(:action, :background, :additional_details)
    include Browseable, NearestNeighbours, Taggable, Departments, Topics, Anonymization

    facet :all, -> { by_most_signatures }
    facet :awaiting_response, -> { awaiting_response.by_waiting_for_response_longest }
    facet :awaiting_debate, -> { awaiting_debate.by_most_relevant_debate_date }
    facet :with_debate_outcome, -> { with_debate_outcome.by_most_recent_debate_outcome }
    facet :with_debated_outcome, -> { with_debated_outcome.by_most_recent_debate_outcome }
    facet :published, -> { published.by_most_signatures }
    facet :stopped, -> { stopped.by_most_signatures }
    facet :closed, -> { closed.by_most_signatures }
    facet :rejected, -> { rejected.by_most_signatures }
    facet :hidden, -> { hidden.by_most_recent }
    facet :with_response, -> { with_response.by_most_signatures }
    facet :debated, -> { debated.by_most_recent_debate_outcome }
    facet :not_debated, -> { not_debated.by_most_recent_debate_outcome }
    facet :by_most_signatures, -> { by_most_signatures }
    facet :by_created_at, -> { by_created_at }

    filter :parliament, ->(id) { where(parliament_id: id) }
    filter :topic, ->(code) { topic(code) }

    default_scope { preload(:parliament) }

    delegate :threshold_for_response, :threshold_for_debate, to: :parliament
    delegate :show_on_a_map?, to: :parliament

    with_options allow_nil: true, prefix: true do
      delegate :name, :email, to: :creator
      delegate :code, :details, to: :rejection
      delegate :summary, :details, :created_at, :updated_at, to: :government_response
      delegate :date, :transcript_url, :video_url, :public_engagement_url, :debate_summary_url, :overview, to: :debate_outcome, prefix: :debate
      delegate :debate_pack_url, to: :debate_outcome, prefix: false
    end

    alias_attribute :open_at, :opened_at

    class << self
      def for_state(state)
        where(state: state)
      end

      def by_created_at
        reorder(created_at: :asc)
      end

      def by_most_recent_debate_outcome
        reorder(debate_outcome_at: :desc, created_at: :desc)
      end

      def by_most_relevant_debate_date
        reorder('scheduled_debate_date ASC NULLS LAST, debate_threshold_reached_at ASC NULLS FIRST')
      end

      def by_waiting_for_debate_longest
        reorder(debate_threshold_reached_at: :asc, created_at: :desc)
      end

      def by_most_recent
        reorder(created_at: :desc)
      end

      def by_most_signatures
        reorder(signature_count: :desc)
      end

      def by_waiting_for_response_longest
        reorder(response_threshold_reached_at: :asc, created_at: :desc)
      end

      def awaiting_response
        response_threshold_reached.not_responded
      end

      def not_responded
        where(government_response_at: nil)
      end

      def with_response
        where.not(government_response_at: nil).preload(:government_response)
      end

      def response_threshold_reached
        where.not(response_threshold_reached_at: nil)
      end

      def published
        where(state: PUBLISHED_STATES)
      end

      def moderated
        where(state: MODERATED_STATES)
      end

      def stopped
        where(state: STOPPED_STATE)
      end

      def closed
        where(state: CLOSED_STATE)
      end

      def rejected
        where(state: REJECTED_STATE)
      end

      def hidden
        where(state: HIDDEN_STATE)
      end

      def debateable
        where(state: DEBATABLE_STATES)
      end

      def awaiting_debate
        where(debate_state: %w[awaiting scheduled])
      end

      def debated
        where(debate_state: 'debated').preload(:debate_outcome)
      end

      def not_debated
        where(debate_state: 'not_debated')
      end

      def debate_threshold_reached
        where.not(debate_threshold_reached_at: nil)
      end

      def debate_scheduled
        where.not(scheduled_debate_date: nil)
      end

      def not_scheduled
        where(scheduled_debate_date: nil)
      end

      def with_debate_outcome
        where.not(debate_outcome_at: nil)
      end

      def with_debated_outcome
        debated.where.not(debate_outcome_at: nil)
      end

      def visible
        where(state: VISIBLE_STATES)
      end

      def in_need_of_marking_as_debated(date = Date.current)
        where(scheduled_debate_state.and(debate_date_in_the_past(date)))
      end

      def mark_petitions_as_debated!(date = Date.current)
        in_need_of_marking_as_debated(date).update_all(debate_state: 'debated')
      end

      def removed
        where(state: REMOVED_STATE)
      end

      def hidden_after_publishing
        where(state: HIDDEN_STATE).where.not(opened_at: nil)
      end

      def removed?(id)
        removed.or(hidden_after_publishing).exists?(id)
      end

      def can_anonymize?
        where(anonymized_at: nil).where(do_not_anonymize: [nil, false]).any?
      end

      private

      def debate_date_in_the_past(date)
        arel_table[:scheduled_debate_date].lt(date)
      end

      def scheduled_debate_state
        arel_table[:debate_state].eq('scheduled')
      end

      def threshold_for_debate_reached
        arel_table[:debate_threshold_reached_at].not_eq(nil)
      end

      def scheduled_for_debate
        arel_table[:scheduled_debate_date].not_eq(nil)
      end
    end

    def content
      "#{action} - #{background}"
    end

    def notes?
      note && note.details.present?
    end

    def moderated?
      state.in?(MODERATED_STATES)
    end

    def can_have_debate_added?
      state.in?(DEBATABLE_STATES)
    end

    def stopped?
      state == STOPPED_STATE
    end

    def closed?
      state == CLOSED_STATE
    end

    def rejected?
      state == REJECTED_STATE
    end

    def hidden?
      state == HIDDEN_STATE
    end

    def rejection?
      rejected? || hidden?
    end

    def published?
      state.in?(PUBLISHED_STATES)
    end

    def visible?
      state.in?(VISIBLE_STATES)
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

    def duration
      if parliament.petition_duration?
        parliament.petition_duration
      elsif opened_at?
        calculate_petition_duration
      else
        0
      end
    end

    def closed_early_due_to_election?
      closed_at == parliament.dissolution_at
    end

    def government_response?
      government_response_at && government_response
    end

    def threshold_for_debate_reached?
      signature_count >= parliament.threshold_for_debate
    end

    def threshold_for_response_reached?
      signature_count >= parliament.threshold_for_response
    end

    def signatures_by_constituency
      if defined?(@_signatures_by_constituency)
        @_signatures_by_constituency
      else
        if hash = read_attribute(:signatures_by_constituency)
          @_signatures_by_constituency = calculate_signatures_by_constituency(hash)
        else
          []
        end
      end
    end

    def signatures_by_country
      if defined?(@_signatures_by_country)
        @_signatures_by_country
      else
        if hash = read_attribute(:signatures_by_country)
          @_signatures_by_country = calculate_signatures_by_country(hash)
        else
          []
        end
      end
    end

    def signatures_by_region
      if defined?(@_signatures_by_region)
        @_signatures_by_region
      else
        if hash = read_attribute(:signatures_by_constituency)
          @_signatures_by_region = calculate_signatures_by_region(hash)
        else
          []
        end
      end
    end

    def get_email_requested_at_for(name)
      self["email_requested_for_#{name}_at"]
    end

    def set_email_requested_at_for(name, to: Time.current)
      update_column("email_requested_for_#{name}_at", to)
    end

    def signatures_to_email_for(name, scope = nil)
      if timestamp = get_email_requested_at_for(name)
        signatures.need_emailing_for(name, since: timestamp, scope: scope)
      else
        raise ArgumentError, "The #{name} email has not been requested for archived petition #{id}"
      end
    end

    def update_debate_state
      self.debate_state = evaluate_debate_state
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

    def debate_outcome?
      debate_outcome_at? && debate_outcome
    end

    def positive_debate_outcome?
      debate_outcome? && debate_outcome.debated?
    end

    private

    def evaluate_debate_state
      if scheduled_debate_date?
        scheduled_debate_date > Date.current ? 'scheduled' : 'debated'
      else
        debate_threshold_reached_at? ? 'awaiting' : 'pending'
      end
    end

    def calculate_petition_duration
      if opened_at + 3.months == closed_at
        3
      elsif opened_at + 6.months == closed_at
        6
      elsif opened_at + 9.months == closed_at
        9
      elsif opened_at + 12.months == closed_at
        12
      else
        Rational(closed_at - opened_at, 86400 * 30).to_f
      end
    end

    def constituency_ids
      self[:signatures_by_constituency].keys
    end

    def constituencies
      @constituencies ||= Constituency.where(external_id: constituency_ids).order(:name)
    end

    def calculate_signatures_by_constituency(hash)
      constituencies.map do |constituency|
        {
          name: constituency.name,
          ons_code: constituency.ons_code,
          mp: constituency.mp_name,
          signature_count: hash[constituency.external_id]
        }
      end
    end

    def location_codes
      self[:signatures_by_country].keys
    end

    def locations
      @locations ||= Location.where(code: location_codes).order(:name)
    end

    def calculate_signatures_by_country(hash)
      locations.map do |location|
        {
          name: location.name,
          code: location.code,
          signature_count: hash[location.code]
        }
      end
    end

    def regions(external_ids)
      Region.where(external_id: external_ids).order(:ons_code)
    end

    def constituency_map
      @constituency_map ||= constituencies.map { |c| [c.external_id, c.region_id] }.to_h
    end

    def calculate_signatures_by_region(by_constituency)
      by_region = Hash.new(0)

      by_constituency.inject(by_region) do |hash, (id, count)|
        hash[constituency_map[id]] += count
        hash
      end

      regions(by_region.keys).map do |region|
        {
          name: region.name,
          ons_code: region.ons_code,
          signature_count: by_region[region.external_id]
        }
      end
    end
  end
end
