module CsvHelper
  def csv_escape(value)
    value.to_s.sub(/\A[-=+@]/) { |v| "%%%2X" % v.ord }.presence
  end
end
