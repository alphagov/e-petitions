module SignatureHelper
  def render_signature_form(stage_manager, form, options = {})
    capture do
      concat render_signature_hidden_details(stage_manager, form, options)
      concat render_signature_ui(stage_manager, form, options)
    end
  end

  def signature_count(key, count)
    t(:"#{key}.html", scope: :"petitions.counts", count: count, formatted_count: number_with_delimiter(count))
  end

  private

  def render_signature_hidden_details(stage_manager, form, options)
    capture do
      concat hidden_field_tag(:stage, stage_manager.stage)
      concat hidden_field_tag(:move, 'next')
      concat render('/signatures/create/signer_hidden', options.merge(signature: stage_manager.stage_object, f: form)) unless stage_manager.stage == 'signer'
    end
  end

  def render_signature_ui(stage_manager, form, options)
    # NOTE: make sure we skip past the existing tabindex-ed elements on the page, no matter which ui we render
    increment(4)
    case stage_manager.stage
    when 'signer'
      render('/signatures/create/signer_ui', options.merge(signature: stage_manager.stage_object, f: form))
    when 'replay-email'
      render('/signatures/create/replay_email_ui', options.merge(signature: stage_manager.stage_object, f: form))
    end
  end
end
