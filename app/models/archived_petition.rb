require 'textacular/searchable'

class ArchivedPetition < ActiveRecord::Base
  OPEN_STATE = 'open'
  REJECTED_STATE = 'rejected'
  STATES = [OPEN_STATE, REJECTED_STATE]

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :state, presence: true, inclusion: STATES

  extend Searchable(:title, :description)
  include Browseable

  facet :all, -> { self.by_created_at }
  facet :open, -> { self.open.by_created_at }
  facet :closed, -> { self.closed.by_created_at }
  facet :rejected, -> { self.rejected.by_created_at }

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
      order(:created_at)
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
