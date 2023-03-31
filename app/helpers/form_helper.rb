module FormHelper
  def form_row(options, &block)
    classes = %w[form-group]
    classes.push options.delete(:class) if options.key?(:class)

    object, field = options.delete(:for)

    if object && (object.errors.attribute_names & Array(field)).present?
      classes.push 'error'
    end

    options[:class] = classes.join(' ')
    content_tag(:div, capture(&block), options)
  end

  def countries_for_select
    Location.menu
  end

  def error_messages_for_field(object, field, options = {})
    if object
      errors = Array(field).map { |f| object.errors[f] }.compact.flatten(1)

      if errors.present?
        content_tag :span, errors.first, { class: 'error-message' }.merge(options)
      end
    end
  end
end
