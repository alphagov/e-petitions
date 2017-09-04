module AdminHelper
  def selected_tags
    @selected_tags ||= Array(params[:tags]).flatten.map(&:to_i).compact.reject(&:zero?)
  end

  def mandatory_field
    content_tag :span, raw(' *'), class: 'mandatory'
  end

  def cms_delete_link(model, options = {})
    options[:model_name] ||= model.name
    options[:url] ||= resource_path(model)
    link_to image_tag('admin/delete.png', :size => "16x16", :alt => "Delete"), options[:url], :data => {
                        :confirm => "WARNING: This action cannot be undone.\nAre you sure you want to delete #{h options[:model_name]}?",
                        :method => :delete
                      }
  end

  def admin_petition_facets_for_select(facets, selected)
    options = admin_petition_facets.map do |facet|
      [I18n.t(facet,  scope: :"petitions.facets.names.admin", quantity: facets[facet]), facet]
    end

    options_for_select(options, selected)
  end

  def admin_archived_petition_facets_for_select(facets, selected)
    options = admin_archived_petition_facets.map do |facet|
      [I18n.t(facet,  scope: :"petitions.facets.names.admin_archived", quantity: facets[facet]), facet]
    end

    options_for_select(options, selected)
  end

  def admin_invalidation_facets_for_select(facets, selected)
    options = admin_invalidation_facets.map do |facet|
      [I18n.t(facet,  scope: :"admin.invalidations.facets.labels", quantity: facets[facet]), facet]
    end

    options_for_select(options, selected)
  end

  def admin_parliaments_for_select(selected)
    options_from_collection_for_select(archived_parliaments, :id, :name, selected)
  end

  def email_petitioners_with_count_submit_button(form, petition, options = {})
    i18n_options = {
      scope: :admin, count: petition.signature_count,
      formatted_count: number_with_delimiter(petition.signature_count)
    }

    html_options = {
      name: 'save_and_email', class: 'button',
      data: { confirm: t(:email_confirm, i18n_options) }
    }.merge(options)

    form.submit(t(:email_button, i18n_options), html_options)
  end

  def trending_domains(since: 1.hour.ago, limit: 10)
    @trending_domains ||= build_trending_domains(since, limit)
  end

  def trending_domains?(since: 1.hour.ago, limit: 10)
    !trending_domains(since: since, limit: limit).empty?
  end

  def trending_ips(since: 1.hour.ago, limit: 10)
    @trending_ips ||= build_trending_ips(since, limit)
  end

  def trending_ips?(since: 1.hour.ago, limit: 10)
    !trending_ips(since: since, limit: limit).empty?
  end

  private

  def admin_petition_facets
    I18n.t(:admin, scope: :"petitions.facets")
  end

  def admin_archived_petition_facets
    I18n.t(:admin_archived, scope: :"petitions.facets")
  end

  def admin_invalidation_facets
    I18n.t(:keys, scope: :"admin.invalidations.facets")
  end

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def build_trending_domains(since, limit)
    all_domains = Signature.trending_domains(since: since, limit: limit + 30)
    allowed_domains = rate_limit.allowed_domains_list

    all_domains.inject([]) do |domains, (domain, count)|
      return domains if domains.size == limit

      unless allowed_domains.any?{ |d| d === domain }
        domains << [domain, count]
      end

      domains
    end
  end

  def build_trending_ips(since, limit)
    all_ips = Signature.trending_ips(since: since, limit: limit + 30)
    allowed_ips = rate_limit.allowed_ips_list

    all_ips.inject([]) do |ips, (ip, count)|
      return ips if ips.size == limit

      unless allowed_ips.any?{ |i| i.include?(ip) }
        ips << [ip, count]
      end

      ips
    end
  end
end
