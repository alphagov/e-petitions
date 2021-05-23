module PostcodeSanitizer
  def self.call(postcode)
    postcode.to_s.gsub(/\s+|-+|–+|—+|[^a-zA-Z0-9]+/, "").upcase
  end
end
