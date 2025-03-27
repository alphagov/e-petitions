module NormalizeLines
  def self.call(string)
    string.encode(universal_newline: true)
  end
end
