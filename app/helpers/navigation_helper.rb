module NavigationHelper
  def navigation_item(name, url, page = nil)
    if current_page?(page || url)
      tag.li(link_to(name, url), aria: { current: "true" })
    else
      tag.li(link_to(name, url))
    end
  end
end
