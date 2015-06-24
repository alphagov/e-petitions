module AdminHelper

  def save_button(resource)
    submit_tag 'Save'
  end

  def mandatory_field()
    return '<span class="mandatory">&nbsp;*</span>'
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

  def email_signatures_with_count_submit_button(form, petition)
    counted_signatures = "#{number_with_delimiter(petition.signature_count)} #{'signature'.pluralize}"
    form.submit "Email #{counted_signatures}", data: { confirm: "Are you sure you want to do this and email all #{counted_signatures}?" }
  end
end
