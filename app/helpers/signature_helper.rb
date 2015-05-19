module SignatureHelper
  def render_signature_form(stage_manager, form)
    capture do
      concat render_signature_hidden_details(stage_manager, form)
      concat render_signature_ui(stage_manager, form)
    end
  end

  private

  def render_signature_hidden_details(stage_manager, form)
    capture do
      concat hidden_field_tag(:stage, stage_manager.stage)
      concat render('/signatures/create/signer_hidden', signature: stage_manager.stage_object, f: form) unless stage_manager.stage == 'signer'
    end
  end

  def render_signature_ui(stage_manager, form)
    # NOTE: make sure we skip past the existing tabindex-ed elements on the page, no matter which ui we render
    increment(4)
    case stage_manager.stage
    when 'signer'
      render('/signatures/create/signer_ui', signature: stage_manager.stage_object, f: form)
    when 'replay-email'
      render('/signatures/create/replay_email_ui', signature: stage_manager.stage_object, f: form)
    end
  end
end
