module SocialMetaHelper
  def meta_description_tag
    case params.permit(:controller, :action).to_h
    in {controller: "feedback", action: /\A(new|create|thanks)\z/}
      description = t(:new, scope: :"metadata.description.feedback", default: nil)
    in {controller: "petitions", action: /\A(new|create)\z/}
      description = t(@new_petition.stage, scope: :"metadata.description.petitions.create", default: nil)
    in {controller: "signatures", action: /\A(new|create)\z/}
      description = t(@signature.stage, scope: :"metadata.description.signatures.create", default: nil)
    else
      description = t(params[:action], scope: :"metadata.description.#{params[:controller]}", default: nil)
    end

    if description.present?
      tag.meta(name: 'description', content: description)
    end
  end

  def open_graph_tag(name, content, interpolation = {})
    if Symbol === content
      tag(:meta, property: "og:#{name}", content: t(content, **(interpolation.merge(scope: :'metadata.open_graph'))))
    elsif name == 'image'
      tag(:meta, property: "og:image", content: url_to_image(content))
    else
      tag(:meta, property: "og:#{name}", content: content)
    end
  end

  def x_card_tag(name, content, interpolation = {})
    if Symbol === content
      tag(:meta, name: "twitter:#{name}", content: t(content, **(interpolation.merge(scope: :'metadata.x'))))
    elsif name == 'image'
      tag(:meta, name: "twitter:image", content: url_to_image(content))
    else
      tag(:meta, name: "twitter:#{name}", content: content)
    end
  end
end
