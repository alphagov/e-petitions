require 'redcarpet/render_strip'

module MarkdownHelper
  HTML_DEFAULTS = {
    escape_html: false, filter_html: false,
    hard_wrap: true, xhtml: true, safe_links_only: true,
    no_styles: true, no_images: true, no_links: false,
    with_toc_data: false, prettify: false, link_attributes: {}
  }

  PARSER_DEFAULTS = {
    no_intra_emphasis: true, tables: false, fenced_code_blocks: false,
    autolink: true, disable_indented_code_blocks: false, strikethrough: true,
    lax_spacing: false, space_after_headers: true, superscript: true,
    underline: false, highlight: false, quote: false, footnotes: false
  }

  DEFAULT_ALLOWED_TAGS = Rails::HTML::SafeListSanitizer::DEFAULT_ALLOWED_TAGS
  EXTRA_ALLOWED_TAGS = Set.new(%w[table thead tbody tr th td])
  ALLOWED_TAGS = DEFAULT_ALLOWED_TAGS + EXTRA_ALLOWED_TAGS

  DEFAULT_ALLOWED_ATTRIBUTES = Rails::HTML::SafeListSanitizer::DEFAULT_ALLOWED_ATTRIBUTES
  EXTRA_ALLOWED_ATTRIBUTES = Set.new(%w[id])
  ALLOWED_ATTRIBUTES = DEFAULT_ALLOWED_ATTRIBUTES + EXTRA_ALLOWED_ATTRIBUTES

  SANITIZE_DEFAULTS = {
    tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES, scrubber: nil
  }

  class CustomHTMLRenderer < Redcarpet::Render::HTML
    def header(text, level)
      text, id = text.split('|', 2)

      if id.present?
        %(<h#{level} id="#{id}">#{text}</h#{level}>\n)
      else
        %(<h#{level}>#{text}</h#{level}>\n)
      end
    end
  end

  class CustomTextRenderer < Redcarpet::Render::StripDown
    def header(text, level)
      %(#{text.split('|', 2).first}\n)
    end
  end

  def markdown_to_html(markup, options = {})
    sanitize_markdown(markdown_parser(html_renderer(options), options).render(markup), options)
  end

  def markdown_to_text(markup, options = {})
    markdown_parser(text_renderer, options).render(markup)
  end

  private

  def html_renderer(options)
    CustomHTMLRenderer.new(options_for_renderer(options))
  end

  def text_renderer
    CustomTextRenderer.new
  end

  def markdown_parser(renderer, options)
    Redcarpet::Markdown.new(renderer, options_for_parser(options))
  end

  def options_for_parser(options)
    PARSER_DEFAULTS.merge(options.slice(*PARSER_DEFAULTS.keys))
  end

  def options_for_renderer(options)
    HTML_DEFAULTS.merge(options.slice(*HTML_DEFAULTS.keys))
  end

  def sanitize_markdown(html, options)
    sanitize(html, options_for_sanitize(options))
  end

  def options_for_sanitize(options)
    SANITIZE_DEFAULTS.merge(options.slice(*SANITIZE_DEFAULTS.keys))
  end
end
