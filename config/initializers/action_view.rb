ActiveSupport.on_load(:action_view) do
  # Monkey patch tag method to generate void tags instead of self-closing tags
  ActionView::Helpers::TagHelper.module_eval do
    remove_possible_method :tag

    def tag(name = nil, options = nil, open = false, escape = true)
      if name.nil?
        tag_builder
      else
        ensure_valid_html5_tag_name(name)
        "<#{name}#{tag_builder.tag_options(options, escape) if options}>".html_safe
      end
    end
  end

  # Monkey patch CheckBox to remove autocomplete="off"
  ActionView::Helpers::Tags::CheckBox.class_eval do
    private

    remove_possible_method :hidden_field_for_checkbox

    def hidden_field_for_checkbox(options)
      @unchecked_value ? tag("input", options.slice("name", "disabled", "form").merge!("type" => "hidden", "value" => @unchecked_value)) : "".html_safe
    end
  end

  # Monkey patch HiddenField to remove autocomplete="off"
  ActionView::Helpers::Tags::HiddenField.class_eval do
    remove_possible_method :render

    def render
      super
    end
  end

  # Monkey patch hidden_field_tag to remove autocomplete="off"
  ActionView::Helpers::FormTagHelper.class_eval do
    remove_possible_method :hidden_field_tag

    def hidden_field_tag(name, value = nil, options = {})
      text_field_tag(name, value, options.merge(type: :hidden))
    end
  end

  # Monkey patch token_tag and method_tag to remove autocomplete="off"
  ActionView::Helpers::UrlHelper.class_eval do
    remove_possible_method :token_tag

    def token_tag(token = nil, form_options: {})
      if token != false && defined?(protect_against_forgery?) && protect_against_forgery?
        token =
          if token == true || token.nil?
            form_authenticity_token(form_options: form_options.merge(authenticity_token: token))
          else
            token
          end
        tag(:input, type: "hidden", name: request_forgery_protection_token.to_s, value: token)
      else
        ""
      end
    end

    remove_possible_method :method_tag

    def method_tag(method)
      tag("input", type: "hidden", name: "_method", value: method.to_s)
    end
  end
end
