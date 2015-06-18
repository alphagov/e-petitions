module PetitionHelper
  def render_petition_form(stage_manager, form)
    capture do
      concat render_petition_hidden_details(stage_manager, form)
      concat render_petition_ui(stage_manager, form)
    end
  end

  def rejection_reasons
    t(:"petitions.rejection_reasons.titles").map do |value, label|
      if value.to_s.in?(Petition::HIDDEN_REJECTION_CODES)
        ["#{label} (will be hidden)", value]
      else
        [label, value]
      end
    end
  end

  def rejection_descriptions
    t(:"petitions.rejection_reasons.descriptions")
  end

  def waiting_for_response_in_words(petition)
    if petition.response_threshold_reached_at
      waiting_in_days(petition)
    end
  end

  def waiting_for_debate_date_in_words(petition)
    if petition.debate_threshold_reached_at
      waiting_in_days(petition)
    end
  end

  private

  def render_petition_hidden_details(stage_manager, form)
    capture do
      concat hidden_field_tag(:stage, stage_manager.stage)
      concat hidden_field_tag(:move, 'next')
      concat render('/petitions/create/petition_details_hidden', petition: stage_manager.stage_object, f: form) unless stage_manager.stage == 'petition'
      if stage_manager.stage_object.creator_signature.present?
        concat render('/petitions/create/your_details_hidden', petition: stage_manager.stage_object, f: form) unless stage_manager.stage == 'creator'
        concat render('/petitions/create/email_hidden', petition: stage_manager.stage_object, f: form) unless ['creator', 'replay-email'].include? stage_manager.stage
      end
    end
  end

  def render_petition_ui(stage_manager, form)
    # NOTE: make sure we skip past the existing tabindex-ed elements on the page, no matter which ui we render
    increment(4)
    case stage_manager.stage
    when 'petition'
      render('/petitions/create/petition_details_ui', petition: stage_manager.stage_object, f: form)
    when 'creator'
      render('/petitions/create/your_details_ui', petition: stage_manager.stage_object, f: form)
    when 'replay-petition'
      render('/petitions/create/replay_petition_ui', petition: stage_manager.stage_object, f: form)
    when 'replay-email'
      render('/petitions/create/replay_email_ui', petition: stage_manager.stage_object, f: form)
    end
  end

  def waiting_in_days(petition)
    scope = :"petitions.waiting_for_date_in_words"
    now   = Time.current.end_of_day
    if petition.response_threshold_reached_at
      from = petition.response_threshold_reached_at.end_of_day
    elsif petition.debate_threshold_reached_at
      from = petition.debate_threshold_reached_at.end_of_day
    end
    count = ((now - from) / 86400.0).floor

    key = case count
            when 0 then :zero
            when 1 then :one
            else :other
          end

    t(key, scope: scope, formatted_count: number_with_delimiter(count))
  end
end
