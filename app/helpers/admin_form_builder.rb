class AdminFormBuilder < ActionView::Helpers::FormBuilder

  [:text_field, :text_area, :password_field].each do |field_type|
    class_eval <<-end_src, __FILE__, __LINE__
      # Keep an alias to the original so we can refer to them in specialised versions of the standard helpers
      alias :original_#{field_type} :#{field_type}
      def #{field_type}(field, options = {})
        options = options.dup
        wrapper_class = add_css_class(options.delete(:wrapper_class), 'form_field')
        field_suffix = options.delete(:field_suffix)
        body = ActiveSupport::SafeBuffer.new
        body << label(field, options.delete(:label), :class => options.delete(:label_class))
        body << @template.mandatory_field().html_safe if options.delete(:is_mandatory)
        body << "<br/>\n".html_safe << super
        body << ' ' << field_suffix if field_suffix
        @template.content_tag(:p, body, :class => wrapper_class)
      end
    end_src
  end
  
  alias :original_check_box :check_box
  def check_box(field, options = {}, checked_value = "1", unchecked_value = "0")
    options = options.dup
    label = label(field, options.delete(:label), :class => options.delete(:label_class))
    label += @template.mandatory_field() if options.delete(:is_mandatory)
    wrapper_class = add_css_class(options.delete(:wrapper_class), 'form_field')
    @template.content_tag(:p, super + label, :class => wrapper_class)
  end

  def label(field, text = nil, options = {})
    text ||= object.class.human_attribute_name(field) unless object.nil?
    super
  end

  def datetime_text_field(field, options = {})
    text_field(field, options.reverse_merge(:field_suffix => '(yyyy-mm-dd hh:mm:ss)'))
  end

  def image_file_field(field, options = {})
    options = options.dup
    if object.send(field).file?
      options[:preview_content] = @template.image_tag( object.send(field).url(:thumbnail), :class => "thumbnail" )
    end
    file_field(field, options)
  end

  private

  def add_css_class(classes, new_class)
    classes ||= ''
    classes += " #{new_class}"
    classes.strip
  end
end
