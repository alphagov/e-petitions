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

  def markdown_to_html(markup, options = {})
    markdown_parser(html_renderer(options), options).render(markup).html_safe
  end

  def markdown_to_text(markup, options = {})
    markdown_parser(text_renderer, options).render(markup).html_safe
  end

  private

  def html_renderer(options)
    Redcarpet::Render::HTML.new(options_for_renderer(options))
  end

  def text_renderer
    Redcarpet::Render::StripDown.new
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
end
