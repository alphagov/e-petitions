module PostcodeSanitizer
  PATTERN = /\s+|-+|–+|—+|[^a-zA-Z0-9]+/.freeze
  BLANK = "".freeze

  class << self
    def call(postcode)
      postcode.to_s.gsub(PATTERN, BLANK).upcase
    end
  end
end
