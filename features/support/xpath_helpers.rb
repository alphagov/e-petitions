module XPathHelpers
  def self.class_matching(class_name)
    "[contains(concat(' ', normalize-space(@class), ' '), ' #{class_name} ')]"
  end
end
