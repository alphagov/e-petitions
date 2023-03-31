module Statistics
  class << self
    def [](form)
      case form
      when 'signature_counts'
        SignatureCounts::Form
      else
        ModerationPerformance::Form
      end
    end
  end
end
