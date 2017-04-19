class Parliament < ActiveRecord::Base
  class << self
    def before_remove_const
      Thread.current[:__parliament__] = nil
    end

    def instance
      Thread.current[:__parliament__] ||= last_or_create
    end

    def dissolution_at
      instance.dissolution_at
    end

    def dissolution_message
      instance.dissolution_message
    end

    def dissolved?(now = Time.current)
      instance.dissolved?(now)
    end

    def dissolution_announced?
      instance.dissolution_announced?
    end

    def reload
      Thread.current[:__parliament__] = nil
    end

    def last_or_create
      order(created_at: :desc).first_or_create
    end
  end

  def dissolved?(now = Time.current)
    dissolution_at? && dissolution_at < now
  end

  def dissolution_announced?
    dissolution_at?
  end
end
