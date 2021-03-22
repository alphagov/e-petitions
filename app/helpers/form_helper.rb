module FormHelper
  COUNTRY_DIVIDER = [["--------------------", "", { disabled: true }]]

  def form_row(options, &block)
    classes = %w[form-group]
    classes.push options.delete(:class) if options.key?(:class)

    object, field = options.delete(:for)
    classes.push 'error' if object && object.errors[field].any?

    options[:class] = classes.join(' ')
    content_tag(:div, capture(&block), options)
  end

  def countries_for_select
    t(:priority_countries) + COUNTRY_DIVIDER + t(:countries)
  end

  def countries_for_create
    [[t(:"country_name.GB-WLS"), "GB-WLS"]]
  end

  def error_messages_for_field(object, field_name, options = {})
    if errors = object && object.errors[field_name].presence
      content_tag :span, errors.first, { class: 'error-message' }.merge(options)
    end
  end
end
