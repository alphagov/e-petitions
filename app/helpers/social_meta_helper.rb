module SocialMetaHelper
  def open_graph_tag(name, content, interpolation = {})
    if Symbol === content
      tag(:meta, property: "og:#{name}", content: t(content, interpolation.merge(scope: :'metadata.open_graph')))
    elsif name == 'image'
      tag(:meta, property: "og:image", content: url_to_image(content))
    else
      tag(:meta, property: "og:#{name}", content: content)
    end
  end

  def twitter_card_tag(name, content, interpolation = {})
    if Symbol === content
      tag(:meta, name: "twitter:#{name}", content: t(content, interpolation.merge(scope: :'metadata.twitter')))
    elsif name == 'image'
      tag(:meta, name: "twitter:image", content: url_to_image(content))
    else
      tag(:meta, name: "twitter:#{name}", content: content)
    end
  end
end
