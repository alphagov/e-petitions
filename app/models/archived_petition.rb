require 'textacular/searchable'

class ArchivedPetition < ActiveRecord::Base
  OPEN_STATE = 'open'
  CLOSED_STATE = 'closed'
  REJECTED_STATE = 'rejected'
  STATES = [OPEN_STATE, CLOSED_STATE, REJECTED_STATE]

  alias_attribute :action, :title

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :state, presence: true, inclusion: STATES
  validates :closed_at, presence: true, unless: :rejected?

  extend Searchable(:title, :description)
  include Browseable

  facet :all, -> { by_created_at }
  facet :open, -> { for_state(OPEN_STATE).by_created_at }
  facet :closed, -> { for_state(CLOSED_STATE).by_created_at }
  facet :rejected, -> { for_state(REJECTED_STATE).by_created_at }
  facet :by_most_signatures, -> { by_most_signatures }

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
end
