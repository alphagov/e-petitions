module DateTimeHelper
  def short_date_format(date_time)
    date_time && date_time.strftime("%e %B %Y")
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
end
