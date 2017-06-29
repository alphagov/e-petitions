require 'textacular/searchable'

module Archived
  class Petition < ActiveRecord::Base
    STOPPED_STATE = 'stopped'
    CLOSED_STATE = 'closed'
    HIDDEN_STATE = 'hidden'
    REJECTED_STATE = 'rejected'
    STATES = [STOPPED_STATE, CLOSED_STATE, HIDDEN_STATE, REJECTED_STATE]
    PUBLISHED_STATES = [CLOSED_STATE]
    VISIBLE_STATES = [CLOSED_STATE, REJECTED_STATE]

    belongs_to :parliament, inverse_of: :petitions, required: true

    has_one :creator, -> { where(creator: true) }, class_name: "Signature"
    has_one :debate_outcome, dependent: :destroy
    has_one :government_response, dependent: :destroy
    has_one :note, dependent: :destroy
    has_one :rejection, dependent: :destroy

    has_many :emails, :dependent => :destroy
    has_many :signatures
    has_many :sponsors, -> { where(sponsor: true) }, class_name: "Signature"

    validates :action, presence: true, length: { maximum: 150 }
    validates :background, length: { maximum: 300 }, allow_blank: true
    validates :additional_details, length: { maximum: 1000 }, allow_blank: true
    validates :state, presence: true, inclusion: STATES
    validates :closed_at, presence: true, if: :closed?

    extend Searchable(:action, :background, :additional_details)
    include Browseable

    filter :parliament

    facet :all, -> { visible.by_most_signatures }
    facet :published, -> { for_state(PUBLISHED_STATES).by_most_signatures }
    facet :stopped, -> { for_state(STOPPED_STATE).by_most_signatures }
    facet :closed, -> { for_state(CLOSED_STATE).by_most_signatures }
    facet :rejected, -> { for_state(REJECTED_STATE).by_most_signatures }
    facet :with_response, -> { with_response.by_most_signatures }
    facet :debated, -> { debated.by_most_recent_debate_outcome }
    facet :not_debated, -> { not_debated.by_most_recent_debate_outcome }
    facet :by_most_signatures, -> { by_most_signatures }
    facet :by_created_at, -> { by_created_at }

    default_scope { preload(:parliament) }

    delegate :threshold_for_response, :threshold_for_debate, to: :parliament

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

      def by_most_signatures
        reorder(signature_count: :desc)
      end

      def with_response
        where.not(government_response_at: nil)
      end

      def debated
        where(debate_state: 'debated')
      end

      def not_debated
        where(debate_state: 'not_debated')
      end

      def visible
        where(state: VISIBLE_STATES)
      end
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
        if signatures_by_constituency?
          @_signatures_by_constituency = calculate_signatures_by_constituency(super)
        else
          []
        end
      end
    end

    def signatures_by_country
      if defined?(@_signatures_by_country)
        @_signatures_by_country
      else
        if signatures_by_country?
          @_signatures_by_country = calculate_signatures_by_country(super)
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

    def signatures_to_email_for(name)
      if timestamp = get_email_requested_at_for(name)
        signatures.need_emailing_for(name, since: timestamp)
      else
        raise ArgumentError, "The #{name} email has not been requested for petition #{id}"
      end
    end

    private

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

    def constituencies(external_ids)
      Constituency.where(external_id: external_ids).order(:name)
    end

    def calculate_signatures_by_constituency(hash)
      constituencies(hash.keys).map do |constituency|
        {
          name: constituency.name,
          ons_code: constituency.ons_code,
          mp: constituency.mp_name,
          signature_count: hash[constituency.external_id]
        }
      end
    end

    def locations(codes)
      Location.where(code: codes).order(:name)
    end

    def calculate_signatures_by_country(hash)
      locations(hash.keys).map do |location|
        {
          name: location.name,
          code: location.code,
          signature_count: hash[location.code]
        }
      end
    end
  end
end
