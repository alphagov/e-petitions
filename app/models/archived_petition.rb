require 'textacular/searchable'

class ArchivedPetition < ActiveRecord::Base
  OPEN_STATE = 'open'
  REJECTED_STATE = 'rejected'
  STATES = [OPEN_STATE, REJECTED_STATE]

  alias_attribute :action, :title

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :state, presence: true, inclusion: STATES

  extend Searchable(:title, :description)
  include Browseable

  facet :all, -> { by_created_at }
  facet :open, -> { open.by_created_at }
  facet :closed, -> { closed.by_created_at }
  facet :rejected, -> { rejected.by_created_at }
  facet :by_most_signatures, -> { by_most_signatures }

  class << self
    def closed(time = Time.current)
      where(open_state.and(closed_at_has_passed(time)))
    end

    def open(time = Time.current)
      where(open_state.and(closed_at_has_not_passed(time)))
    end

    def rejected
      where(rejected_state)
    end

    def by_created_at
      reorder(:created_at)
    end

    def by_most_signatures
      order("signature_count DESC")
    end

    private

    def closed_at_has_not_passed(time)
      arel_table[:closed_at].gteq(time)
    end

    def closed_at_has_passed(time)
      arel_table[:closed_at].lt(time)
    end

    def open_state
      arel_table[:state].eq(OPEN_STATE)
    end

    def rejected_state
      arel_table[:state].eq(REJECTED_STATE)
    end
  end

  def open?
    state == OPEN_STATE && closed_at.nil?
  end

  def closed?(time = Time.current)
    state == OPEN_STATE && !!closed_at && closed_at <= time
  end

  def rejected?
    state == REJECTED_STATE
  end
end
