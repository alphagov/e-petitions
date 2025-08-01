module AdminHelper
  ISO8601_TIMESTAMP = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/

  def message_colours
    [
      %w[Default default],
      %w[Grey grey],
      %w[Orange orange],
      %w[Red red],
      %w[Black black]
    ]
  end

  def selected_depts
    @selected_depts ||= Array(params[:depts]).flatten.map(&:to_i).compact.reject(&:zero?)
  end

  def selected_tags
    @selected_tags ||= Array(params[:tags]).flatten.map(&:to_i).compact.reject(&:zero?)
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

  def admin_signature_states_for_select(selected)
    options_for_select(I18n.t(:states, scope: :"admin.signature"), selected)
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
      data: { confirm: t(:email_confirm, **i18n_options) }
    }.merge(options)

    form.submit(t(:email_button, **i18n_options), html_options)
  end

  def fraudulent_domains?(since: 1.hour.ago, limit: 10)
    !fraudulent_domains(since: since, limit: limit).empty?
  end

  def fraudulent_domains(since: 1.hour.ago, limit: 10)
    @fraudulent_domains ||= build_fraudulent_domains(since, limit)
  end

  def fraudulent_ips?(since: 1.hour.ago, limit: 10)
    !fraudulent_ips(since: since, limit: limit).empty?
  end

  def fraudulent_ips(since: 1.hour.ago, limit: 10)
    @fraudulent_ips ||= build_fraudulent_ips(since, limit)
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

  def trending_window?
    params[:window].present? && params[:window] =~ ISO8601_TIMESTAMP
  end

  def trending_window
    if trending_window?
      starts_at = params[:window].in_time_zone
      ends_at = starts_at.advance(hours: 1)

      starts_at..ends_at
    end
  end

  def signature_count_interval_menu
    {
      "1 second" => "1",
      "2 seconds" => "2",
      "5 seconds" => "5",
      "10 seconds" => "10",
      "30 seconds" => "30",
      "1 minute" => "60",
      "5 minutes" => "300"
    }
  end

  def back_link
    if session[:back_location]
      link_to "Back", session[:back_location], class: "back-link"
    elsif @petition && @petition.is_a?(Archived::Petition)
      link_to "Back", admin_archived_petitions_path, class: "back-link"
    elsif @petition
      link_to "Back", admin_petitions_path, class: "back-link"
    else
      link_to "Back", admin_root_path, class: "back-link"
    end
  end

  def show_closing_column?(scope)
    scope.in?(%i[open closed])
  end

  def show_rejection_column?(scope)
    scope.in?(%i[rejected hidden])
  end

  def short_rejection_reason(rejection)
    t(rejection.code, scope: :"rejection.reasons.short", default: rejection.code.titleize)
  end

  def parliament_tab
    if (errors = @parliament.errors.attribute_names).present?
      if (errors & %i[government opening_at]).present?
        "details"
      elsif (errors & %i[dissolution_at dissolution_faq_url show_dissolution_notification dissolution_heading dissolution_message]).present?
        "dissolution"
      elsif (errors & %i[notification_cutoff_at dissolved_heading dissolved_message]).present?
        "dissolved"
      elsif (errors & %i[election_date registration_closed_at]).present?
        "election"
      elsif (errors & %i[government_response_heading government_response_description government_response_status]).present?
        "response"
      elsif (errors & %i[parliamentary_debate_heading parliamentary_debate_description parliamentary_debate_status]).present?
        "debate"
      else
        "details"
      end
    else
      params.fetch(:tab, "details")
    end
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

  def build_fraudulent_domains(since, limit)
    Signature.fraudulent_domains(since: since, limit: limit)
  end

  def build_fraudulent_ips(since, limit)
    Signature.fraudulent_ips(since: since, limit: limit)
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
