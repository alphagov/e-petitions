module DateTimeHelper
  WAITING_FOR_KEYS = Hash.new(:other).merge(0 => :zero, 1 => :one)
  TO_BE_DEBATED_KEYS = Hash.new(:other).merge(0 => :today, 1 => :tomorrow)

  def short_date_format(date_time)
    date_time && date_time.strftime("%-d %B %Y")
  end

  def short_date_time_format(date_time)
    date_time && date_time.strftime("%H:%M%P on %-d %B %Y")
  end

  def date_time_format(date_time)
    date_time && date_time.strftime("%d-%m-%Y %H:%M")
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

  def waiting_for_in_words(date, now = Time.current)
    return unless date.present?

    scope = :"petitions.waiting_for_in_words"
    days  = ((now.end_of_day - date.end_of_day) / 86400.0).round
    key   = WAITING_FOR_KEYS[days]

    t(key, scope: scope, formatted_count: number_with_delimiter(days))
  end

  def api_date_format(date_time)
    if date_time
      if date_time.respond_to?(:getutc)
        date_time.getutc.iso8601(3)
      else
        date_time.strftime("%Y-%m-%d")
      end
    end
  end

  def scheduled_for_debate_in_words(date, today = Date.current)
    scope = :"petitions.scheduled_for_debate_in_words"
    days  = (date - today).to_i
    key   = TO_BE_DEBATED_KEYS[days]

    t(key, scope: scope, formatted_date: short_date_format(date))
  end

  def christmas_period?(today = Date.current)
    Holiday.christmas?(today)
  end

  def easter_period?(today = Date.current)
    Holiday.easter?(today)
  end
end
