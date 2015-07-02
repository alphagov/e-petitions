module RejectionHelper
  def rejection_reason(code)
    t(:"#{code}", scope: :"rejections.titles")
  end

  def rejection_description(code)
    unless code.blank?
      t(:"#{code}", scope: :"rejections.descriptions").html_safe
    end
  end

  def rejection_reasons
    t(:"rejections.titles").map do |value, label|
      if value.to_s.in?(Rejection::HIDDEN_CODES)
        ["#{label} (will be hidden)", value]
      else
        [label, value]
      end
    end
  end

  def rejection_descriptions
    t(:"rejections.descriptions")
  end
end
