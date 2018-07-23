module PostcodeSanitizer
  def self.call(postcode)
    postcode.to_s.gsub(/\s+|-+|–+|—+/, "").upcase
  end
end
