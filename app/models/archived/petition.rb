require 'textacular/searchable'

module Archived
  class Petition < ActiveRecord::Base
    OPEN_STATE = 'open'
    CLOSED_STATE = 'closed'
    HIDDEN_STATE = 'hidden'
    REJECTED_STATE = 'rejected'
    STATES = [OPEN_STATE, CLOSED_STATE, HIDDEN_STATE, REJECTED_STATE]
    PUBLISHED_STATES = [OPEN_STATE, CLOSED_STATE]

    belongs_to :parliament, inverse_of: :petitions, required: true

    has_one :creator, -> { where(creator: true) }, class_name: "Signature"
    has_one :debate_outcome, dependent: :destroy
    has_one :government_response, dependent: :destroy
    has_one :note, dependent: :destroy
    has_one :rejection, dependent: :destroy

    has_many :emails, :dependent => :destroy
    has_many :signatures
    has_many :sponsors, -> { where(sponsor: true) }, class_name: "Signature"

    validates :title, presence: true, length: { maximum: 150 }
    validates :description, presence: true, length: { maximum: 1000 }
    validates :state, presence: true, inclusion: STATES
    validates :closed_at, presence: true, unless: :rejected?

    extend Searchable(:title, :description)
    include Browseable

    filter :parliament

    facet :all, -> { by_most_signatures }
    facet :published, -> { for_state(PUBLISHED_STATES).by_most_signatures }
    facet :open, -> { for_state(OPEN_STATE).by_most_signatures }
    facet :closed, -> { for_state(CLOSED_STATE).by_most_signatures }
    facet :rejected, -> { for_state(REJECTED_STATE).by_most_signatures }
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

      def by_most_signatures
        reorder(signature_count: :desc)
      end
    end

    def action
      super || title
    end

    def action?
      super || title?
    end

    def open?
      state == OPEN_STATE
    end

    def closed?
      state == CLOSED_STATE
    end

    def rejected?
      state == REJECTED_STATE
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

    def threshold_for_debate_reached?
      signature_count >= parliament.threshold_for_debate
    end

    def threshold_for_response_reached?
      signature_count >= parliament.threshold_for_response
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
  end
end
