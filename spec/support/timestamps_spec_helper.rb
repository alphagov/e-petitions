module TimestampsSpecHelper
  def timestampify(time)
    time.getutc.iso8601(3) unless time.nil?
  end

  def datestampify(date)
    date.strftime("%Y-%m-%d") unless date.nil?
  end
end
