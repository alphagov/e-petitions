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

  def setup_admin_user(admin_user)
    4.times do
      admin_user.departments.build
    end
    admin_user
  end
end