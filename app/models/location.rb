class Location < ActiveRecord::Base
  validates :code, presence: true, length: { maximum: 30 }
  validates :name, presence: true, length: { maximum: 100 }

  class << self
    def by_name
      order(name: :asc)
    end

    def current(today = Date.current)
      not_pending.not_expired.by_name
    end

    def not_pending(today = Date.current)
      where(start_date.eq(nil).or(start_date.lteq(today)))
    end

    def not_expired(today = Date.current)
      where(end_date.eq(nil).or(end_date.gt(today)))
    end

    def menu
      current.pluck(:name, :code)
    end

    private

    def start_date
      arel_table[:start_date]
    end

    def end_date
      arel_table[:end_date]
    end
  end
end
