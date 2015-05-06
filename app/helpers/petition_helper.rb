module PetitionHelper
  def sponsor_email_error_messages(petition)
    sponsor_error_messages = petition.sponsors.map(&:errors).flatten.map(&:messages)
    error_messages = sponsor_error_messages.map { |field_messages| field_messages.values }.flatten
    error_messages << petition.errors[:sponsor_emails]
    content_tag(:div, error_messages.join("</br>\n").html_safe, class: 'errors')
  end

  def render_petition_form(petition, form)
    capture do
      concat render_hidden_details(petition, form)
      concat render_ui(petition, form)
    end
  end

  def render_hidden_details(petition, form)
    capture do
      concat hidden_field_tag(:stage, petition.stage)
      concat render('/petitions/create/petition_details_hidden', petition: petition, f: form) unless petition.stage == 'petition'
      concat render('/petitions/create/sponsor_details_hidden', petition: petition, f: form) unless petition.stage == 'sponsors'
      if petition.creator_signature.present?
        concat render('/petitions/create/your_details_hidden', petition: petition, f: form) unless petition.stage == 'creator'
        concat render('/petitions/create/submit_hidden', petition: petition, f: form) unless petition.stage == 'submit'
      end
    end
  end

  def render_ui(petition, form)
    case petition.stage
    when 'petition'
      render('/petitions/create/petition_details_ui', petition: petition, f: form)
    when 'creator'
      render('/petitions/create/your_details_ui', petition: petition, f: form)
    when 'sponsors'
      render('/petitions/create/sponsor_details_ui', petition: petition, f: form)
    when 'submit'
      render('/petitions/create/submit_ui', petition: petition, f: form)
    end
  end
end
