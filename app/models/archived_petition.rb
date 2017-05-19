require 'textacular/searchable'

class ArchivedPetition < ActiveRecord::Base
  OPEN_STATE = 'open'
  CLOSED_STATE = 'closed'
  REJECTED_STATE = 'rejected'
  STATES = [OPEN_STATE, CLOSED_STATE, REJECTED_STATE]

  alias_attribute :action, :title

  belongs_to :parliament, inverse_of: :petitions, required: true

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :state, presence: true, inclusion: STATES
  validates :closed_at, presence: true, unless: :rejected?

  extend Searchable(:title, :description)
  include Browseable

  filter :parliament

  facet :all, -> { by_most_signatures }
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
    parliament.petition_duration
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
end
