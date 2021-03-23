module DateTimeHelper
  WAITING_FOR_KEYS = Hash.new(:other).merge(0 => :zero, 1 => :one)
  TO_BE_DEBATED_KEYS = Hash.new(:other).merge(0 => :today, 1 => :tomorrow)

  def short_date_format(date_time)
    date_time && I18n.l(date_time, format: "%-d %B %Y")
  end

  def short_date_time_format(date_time)
    date_time && I18n.l(date_time, format: "%H:%M%P on %-d %B %Y")
  end

  def date_time_format(date_time, seconds: false)
    if seconds
      date_time && date_time.strftime("%d-%m-%Y %H:%M:%S")
    else
      date_time && date_time.strftime("%d-%m-%Y %H:%M")
    end
  end

  def date_format(date_time)
    date_time && date_time.strftime("%d/%m/%Y")
  end

  def date_format_admin(date_time)
    date_time && date_time.strftime("%d-%m-%Y")
  end

  def local_date_time_format(date_time)
    date_time && date_time.in_time_zone.strftime("%d/%m/%Y %H:%M")
  end

  def last_updated_at_time(date_time)
    date_time && date_time.in_time_zone.strftime("%H:%M %Z")
  end

  def api_date_format(date_time)
    if date_time
      if date_time.respond_to?(:getutc)
        date_time.getutc.iso8601(3)
      else
        date_time.iso8601
      end
    end
  end

  def csv_date_format(date_time)
    date_time && date_time.strftime("%Y-%m-%d %H:%M:%S")
  end

  def scheduled_for_debate_in_words(date, today = Date.current)
    scope = :"ui.scheduled_for_debate_in_words"
    days  = (date - today).to_i
    key   = TO_BE_DEBATED_KEYS[days]

    t(key, scope: scope, date: short_date_format(date))
  end

  def christmas_period?(today = Date.current)
    Holiday.christmas?(today)
  end

  def easter_period?(today = Date.current)
    Holiday.easter?(today)
  end
end
