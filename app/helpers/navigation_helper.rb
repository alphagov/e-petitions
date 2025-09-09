module NavigationHelper
  def navigation_item(name, page)
    tag.li(link_to(name, page), class: class_names(current: current_page?(page)))
  end
end
