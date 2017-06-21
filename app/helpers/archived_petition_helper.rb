module ArchivedPetitionHelper
  def archived_threshold(petition)
    if petition.threshold_for_response_reached? || petition.government_response?
      petition.threshold_for_debate
    else
      petition.threshold_for_response
    end
  end

  def archived_threshold_percentage(petition)
    threshold = archived_threshold(petition)
    percentage = Rational(petition.signature_count, threshold) * 100
    percentage = [[1, percentage].max, 100].min

    number_to_percentage(percentage, precision: 2)
  end

  def archived_parliaments
    @archived_parliaments ||= Parliament.archived
  end

  def archived_petition_facets_with_counts(petitions)
    petitions.facets.slice(*archived_petition_facets)
  end

  def petition_duration_to_words(duration)
    duration = duration.to_d

    if duration.frac.zero?
      pluralize(duration.floor, "month")
    elsif duration.frac > 0.75
      "nearly #{pluralize(duration.ceil, "month")}"
    elsif duration.frac < 0.25
      "just over #{pluralize(duration.floor, "month")}"
    else
      "over #{pluralize(duration.floor, "month")}"
    end
  end
end
