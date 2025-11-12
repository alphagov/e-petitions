require 'nokogiri'

class InlineStyles
  STYLES = {
    'a' => 'word-wrap: break-word; color: #3569cc;',
    'blockquote' => 'Margin: 0 0 20px 0; border-left: 5px solid #cbc9cd; padding: 15px 0 0.1px 15px; font-size: 19px; line-height: 25px;',
    'hr' => 'border: 0; height: 1px; background: #cbc9cd; Margin: 30px 0 30px 0;',
    'p' => 'Margin: 0 0 20px 0; font-size: 19px; line-height: 25px; color: #212121;',
    'ol' => 'Margin: 0 0 0 20px; padding: 0; list-style-type: decimal;',
    'ul' => 'Margin: 0 0 0 20px; padding: 0; list-style-type: disc;',
    'li' => 'Margin: 5px 0 5px; padding: 0 0 0 5px; font-size: 19px; line-height: 25px; color: #212121;',
    'h1' => 'Margin: 0 0 20px 0; padding: 0; font-size: 27px; line-height: 35px; font-weight: bold; color: #625a75;',
    'h2' => 'Margin: 0 0 15px 0; padding: 10px 0 0 0; font-size: 19px; line-height: 25px; font-weight: bold; color: #625a75;'
  }

  class << self
    def delivering_email(message)
      new(message).transform!
    end

    alias_method :previewing_email, :delivering_email
  end

  def initialize(message)
    @message = message
  end

  def transform!
    return message if html_part.blank?

    each_style do |tag, style|
      inline_styles(tag, style)
    end

    html_part.body = document.to_html

    message
  end

  private

  attr_reader :message

  def html_part
    @html_part ||= message.html_part
  end

  def document
    @document ||= Nokogiri::HTML5(html_part.decoded)
  end

  def each_style(&block)
    STYLES.each(&block)
  end

  def inline_styles(tag, style)
    each_element(tag) { |element| element["style"] = style }
  end

  def each_element(tag, &block)
    document.xpath("//#{tag}").each(&block)
  end
end
