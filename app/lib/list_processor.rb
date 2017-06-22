module ListProcessor
  def strip_comments(list)
    list.gsub(/#.*$/, '')
  end

  def strip_blank_lines(list)
    list.each_line.reject(&:blank?)
  end

  def normalize_lines(value)
    value.to_s.strip.gsub(/\r\n|\r/, "\n")
  end
end
