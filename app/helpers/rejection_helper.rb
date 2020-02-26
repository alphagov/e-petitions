module RejectionHelper
  def rejection_reason(code)
    unless code.blank?
      t(:"#{code}", scope: :"rejections.titles")
    end
  end

  def rejection_description(code)
    unless code.blank?
      simple_format(h(t(:"#{code}", scope: :"rejections.descriptions", threshold_for_referral: Site.formatted_threshold_for_referral)))
    end
  end

  def rejection_reasons
    t(:"rejections.titles").map do |value, label|
      if value.to_s.in?(Rejection::HIDDEN_CODES)
        ["#{label} (#{t(:"rejections.will_be_hidden")})", value]
      else
        [label, value]
      end
    end
  end

  def rejection_descriptions
    Rejection::CODES.map do |code|
      [code, rejection_description(code)]
    end.to_h
  end
end
