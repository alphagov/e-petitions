class Holiday < ActiveRecord::Base
  class << self
    def instance
      Thread.current[:__holiday__] ||= first_or_create(defaults)
    end

    def christmas?(today = Date.current)
      instance.christmas?(today)
    end

    def easter?(today = Date.current)
      instance.easter?(today)
    end

    private

    def defaults
      {
        christmas_start: '2017-12-22',
        christmas_end:   '2018-01-04',
        easter_start:    '2018-03-30',
        easter_end:      '2018-04-09'
      }
    end
  end

  def christmas?(today = Date.current)
    christmas.cover?(today)
  end

  def easter?(today = Date.current)
    easter.cover?(today)
  end

  private

  def christmas
    christmas_start..christmas_end
  end

  def easter
    easter_start..easter_end
  end
end
