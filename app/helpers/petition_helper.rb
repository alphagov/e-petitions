module PetitionHelper
  def render_petition_form(stage_manager, form)
    capture do
      concat render_petition_hidden_details(stage_manager, form)
      concat render_petition_ui(stage_manager, form)
    end
  end

  def public_petition_facets_with_counts(petition_search)
    petition_search.facets.slice(*public_petition_facets)
  end

  def current_threshold(petition)
    if petition.response_threshold_reached_at? || petition.government_response_at?
      Site.threshold_for_debate
    else
      Site.threshold_for_response
    end
  end

  def signatures_threshold_percentage(petition)
    threshold = current_threshold(petition).to_f
    percentage = petition.signature_count / threshold * 100
    if percentage > 100
      percentage = 100
    elsif percentage < 1
      percentage = 1
    end
    number_to_percentage(percentage, precision: 2)
  end

  def petition_list_header
    @_petition_list_header ||= t(@petitions.scope, scope: :"petitions.list_headers", default: "")
  end

  def petition_list_header?
    petition_list_header.present?
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
end
