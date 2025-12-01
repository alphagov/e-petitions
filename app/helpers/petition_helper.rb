module PetitionHelper
  def public_petition_facets_with_counts(petition_search)
    petition_search.facets.slice(*public_petition_facets)
  end

  def current_threshold(petition)
    if petition.debate_threshold_reached_at? || petition.debate_outcome_at?
      petition.threshold_for_debate
    elsif petition.response_threshold_reached_at? || petition.government_response_at?
      petition.threshold_for_debate
    else
      petition.threshold_for_response
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
    @_petition_list_header ||= if @petitions.semantic_search?
      t(:"semantic_html", scope: :"petitions.list_headers", default: "")
    else
      t(:"#{@petitions.scope}_html", scope: :"petitions.list_headers", url: alternative_list_url, default: "")
    end
  end

  def petition_list_header?
    petition_list_header.present?
  end

  def reveal_government_response?
    params[:reveal_response] == "yes"
  end

  def parliament_menu(parliament, &block)
    menu = "parliament-menu-#{parliament.id}"
    label = tag.span("#{parliament.start_year} to #{parliament.end_year}")

    options = {
      type: "button",
      class: "button-menu",
      aria: { expanded: "true", controls: menu }
    }

    tag.button(label, **options) + tag.ul(id: menu, class: "petition-lists", &block)
  end

  def petition_list_item(facet)
    url = petitions_path(@petitions.facet_params(state: facet))
    current = @petitions.scope == facet
    label = t(facet, scope: :"petitions.lists")

    if current
      tag.li(link_to(label, url), aria: { current: "true" })
    else
      tag.li(link_to(label, url))
    end
  end

  def archived_petition_list_item(parliament, facet)
    url = archived_petitions_url(@petitions.facet_params(state: facet, parliament: parliament.id))
    current = @parliament.id == parliament.id && @petitions.scope == facet
    label = t(facet, scope: :"petitions.lists")

    if current
      tag.li(link_to(label, url), aria: { current: "true" })
    else
      tag.li(link_to(label, url))
    end
  end

  private

  def alternative_list_url
    case @petitions.scope
    when :recent
      petitions_path(@petitions.current_params.merge(state: "open"))
    when :open
      petitions_path(@petitions.current_params.merge(state: "recent"))
    else
      petitions_path
    end
  end
end
