class SurveyDistributionJob < ApplicationJob
  def perform(survey_id)
    @survey = Survey.find(survey_id)

    # TODO: Enqueue jobs to mail these petitioners in batches of 1000
    signatures_to_survey.each do |signature|
      SurveyEmailJob.perform_later(signature.email, @survey)
    end
  end

  private

  def signatures_to_survey
    number_of_signatures = (signatures_without_limit.count / 100.0) * @survey.percentage_petitioners

    # TODO: Randomising in this simple way isn't compatible with batch processing of
    # orders. It might be possible to instead pick random IDs from a series of
    # ranges throughout the minimum and maximum ranges for the set of
    # signatures. This set of ranges might have to be dynamically adjusted as we
    # move through the IDs to account for uneven distributions of IDs.
    signatures_without_limit.limit(number_of_signatures.ceil).order('RANDOM()')
  end

  def signatures_without_limit
    query = Signature.where(petition_id: @survey.petition_ids)
    query = query.where(constituency_id: @survey.constituency_id) if @survey.constituency_id
  end
end
