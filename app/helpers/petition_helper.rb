module PetitionHelper
  def public_petition_facets_with_counts(petition_search)
    petition_search.facets.slice(*public_petition_facets)
  end

  def current_threshold(petition)
    if petition.referral_threshold_reached_at?
      Site.threshold_for_debate
    else
      Site.threshold_for_referral
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

  def petition_standards_link(*args)
    link_to(t(:"ui.petitions.standards_link"), help_path(anchor: 'standards'))
  end

  def apply_formatting(petition, attribute)
    text = petition.public_send(attribute)

    if petition.use_markdown?
      markdown_to_html(text)
    else
      auto_link(simple_format(h(text)), html: { rel: 'nofollow' })
    end
  end
end
