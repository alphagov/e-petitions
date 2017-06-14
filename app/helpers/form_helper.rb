module FormHelper
  def form_row opts={}, &block
    css_classes = ['form-group']
    css_classes.push opts[:class] if opts[:class]
    css_classes.push 'error' if opts[:for] && opts[:for][0].errors[opts[:for][1]].any?
    content_tag :div, capture(&block), :class => css_classes.join(' ')
  end

  def countries_for_select
    Location.menu
  end

  def error_messages_for_field(object, field_name, options = {})
    if errors = object && object.errors[field_name].presence
      content_tag :span, errors.first, { class: 'error-message' }.merge(options)
    end
  end

  def css_safe(class_or_id)
    class_or_id.downcase.gsub(/\s+/, '-')
  end
end
