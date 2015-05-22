module PetitionHelper
  def sponsor_email_error_messages(petition)
    sponsor_error_messages = petition.sponsors.map(&:errors).flatten.map(&:messages)
    error_messages = sponsor_error_messages.map { |field_messages| field_messages.values }.flatten
    error_messages << petition.errors[:sponsor_emails]
    content_tag(:div, error_messages.join("</br>\n").html_safe, class: 'errors')
  end

  def render_petition_form(stage_manager, form)
    capture do
      concat render_petition_hidden_details(stage_manager, form)
      concat render_petition_ui(stage_manager, form)
    end
  end

  private

  def render_petition_hidden_details(stage_manager, form)
    capture do
      concat hidden_field_tag(:stage, stage_manager.stage)
      concat render('/petitions/create/petition_details_hidden', petition: stage_manager.stage_object, f: form) unless stage_manager.stage == 'petition'
      concat render('/petitions/create/sponsor_details_hidden', petition: stage_manager.stage_object, f: form) unless stage_manager.stage == 'sponsors'
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
    when 'sponsors'
      render('/petitions/create/sponsor_details_ui', petition: stage_manager.stage_object, f: form)
    when 'replay-petition'
      render('/petitions/create/replay_petition_ui', petition: stage_manager.stage_object, f: form)
    when 'replay-email'
      render('/petitions/create/replay_email_ui', petition: stage_manager.stage_object, f: form)
    end
  end
end
