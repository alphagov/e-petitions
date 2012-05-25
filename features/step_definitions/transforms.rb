# Matches things like "5 days from now" and returns a datetime
Transform /^(\d+) (second|minute|hour|day|week|fortnight|month|year)s? (from[_ ]now|ago)$/ do |number, unit, time_arrow|
  number.to_i.send(unit).send(time_arrow.tr(' ', '_'))
end

Transform /^at (\d+:\d+:\d+) (?:(\d+) (day|week|fortnight|year)s? (from[_ ]now|ago)|today)$/ do |time, number, unit, time_arrow|
  if number.blank?
    date = Date.today
  else
    date = number.to_i.send(unit).send(time_arrow.tr(' ', '_')).to_date
  end
  datetime = Time.zone.parse("#{date} #{time}")
end

Transform /^(-?\d+)$/ do |number_string|
  number_string.to_i
end

Transform /^today$/ do |nothing|
  Date.today.at_midnight
end

Transform /^date in words for (\d+) (second|minute|hour|day|week|fortnight|month|year)s? (from[_ ]now|ago)$/ do |number, unit, time_arrow|
  eval("#{number}.#{unit}.#{time_arrow.tr(' ', '_')}").to_datetime.strftime("%a %-d %b")
end

Transform /^date in long words for (\d+) (second|minute|hour|day|week|fortnight|month|year)s? (from[_ ]now|ago)$/ do |number, unit, time_arrow|
  eval("#{number}.#{unit}.#{time_arrow.tr(' ', '_')}").to_datetime.strftime("%A %-d %b")
end

Transform /^today in words$/ do |nothing|
  Time.zone.now.to_date.strftime("%A %-d %B")
end

Transform /^week day for (\d+) (second|minute|hour|day|week|fortnight|month|year)s? (from[_ ]now|ago)$/ do |number, unit, time_arrow|
  eval("#{number}.#{unit}.#{time_arrow.tr(' ', '_')}").to_datetime.strftime("%A")
end

Transform /^month day for (\d+) (second|minute|hour|day|week|fortnight|month|year)s? (from[_ ]now|ago)$/ do |number, unit, time_arrow|
  eval("#{number}.#{unit}.#{time_arrow.tr(' ', '_')}").to_datetime.strftime("%-d")
end

Transform /^today at (-?\d+)\.(-?\d+)$/ do |hours_str, minutes_str|
  Time.zone.parse((Time.zone.now.at_midnight + hours_str.to_i.hours + minutes_str.to_i.minutes).to_s)
end
