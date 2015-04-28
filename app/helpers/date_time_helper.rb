module DateTimeHelper

  def short_date_format(date_time)
    date_time.strftime("%e %B %Y") if date_time
  end

  def date_time_format(date_time)
    date_time.strftime("%d-%m-%Y %H:%M") if date_time
  end

  def date_format(date_time)
    date_time.to_s(:dotted_short_date) if date_time
  end

  def date_format_admin(date_time)
    date_time.strftime("%d-%m-%Y") if date_time
  end

  def local_date_time_format(date_time)
    return unless date_time
    date_time.in_time_zone.strftime("%d/%m/%Y %H:%M")
  end

  def last_updated_at_time(date_time)
    return unless date_time
    date_time.in_time_zone.strftime("%H:%M %Z")
  end
end
