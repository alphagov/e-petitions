module SignatureHelper
  def progress_bar(petition, &block)
    attributes = {
      value: petition.signature_count,
      max: [
        petition.signature_count,
        petition.threshold_for_response
      ].max
    }

    formatted_count = number_with_delimiter(petition.signature_count)

    if petition.response_threshold_reached_at? || petition.government_response_at?
      signature_max = [petition.signature_count, petition.threshold_for_debate].max
      formatted_threshold = petition.formatted_threshold_for_debate
      suffix = "signatures required to be considered for a debate in Parliament"
    else
      signature_max = [petition.signature_count, petition.threshold_for_response].max
      formatted_threshold = petition.formatted_threshold_for_response
      suffix = "signatures required to get a government response"
    end

    attributes = {
      value: petition.signature_count,
      max: signature_max, aria: {
        valuetext: "#{formatted_count} of #{formatted_threshold} #{suffix}"
      }
    }

    tag.progress(**attributes, &block)
  end

  def signature_count(key, count, options = {})
    t(:"#{key}.html", **(signature_count_options(count, number_with_delimiter(count), options)))
  end

  private

  def signature_count_options(count, formatted_count, options)
    options.reverse_merge(scope: :"petitions.signature_counts", count: count, formatted_count: formatted_count)
  end
end
