module RejectionHelper
  def rejection_reason(code)
    @rejection_reason ||= RejectionReason.find_by(code: code)

    if @rejection_reason.present?
      @rejection_reason.title
    end
  end

  def rejection_description(code)
    @rejection_reason ||= RejectionReason.find_by(code: code)

    if @rejection_reason.present?
      markdown_to_html(@rejection_reason.description)
    end
  end

  def rejection_reasons
    @rejection_reasons ||= RejectionReason.all

    @rejection_reasons.map do |reason|
      [reason.label, reason.code]
    end
  end

  def rejection_descriptions
    @rejection_reasons ||= RejectionReason.all

    @rejection_reasons.each_with_object({}) do |reason, hash|
      hash[reason.code] = markdown_to_html(reason.description)
    end
  end

  def hidden_rejections
    @rejection_reasons ||= RejectionReason.all

    @rejection_reasons.each_with_object({}) do |reason, hash|
      hash[reason.code] = reason.hidden
    end
  end
end
