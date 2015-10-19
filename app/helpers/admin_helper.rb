module AdminHelper

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

  def admin_petition_facets_for_select(selected)
    options_for_select(
      admin_petition_facets.map do |facet|
        [I18n.t(facet,  scope: :"petitions.facets.names.admin", default: facet.to_s.humanize), facet]
      end,
      selected
    )
  end

  def email_petitioners_with_count_submit_button(form, petition)
    i18n_options = {
      scope: :admin, count: petition.signature_count,
      formatted_count: number_with_delimiter(petition.signature_count)
    }

    html_options = {
      name: 'save_and_email', class: 'button',
      data: { confirm: t(:email_confirm, i18n_options) }
    }

    form.submit(t(:email_button, i18n_options), html_options)
  end
end
