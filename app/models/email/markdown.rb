require 'redcarpet/render_strip'

module Email
  module Markdown
    MARKDOWN_EXTENSIONS = {
      no_intra_emphasis: true, tables: false, fenced_code_blocks: false,
      autolink: true, disable_indented_code_blocks: false, strikethrough: true,
      lax_spacing: false, space_after_headers: true, superscript: true,
      underline: true, highlight: true, quote: true, footnotes: false
    }

    module Renderers
      class HTML < Redcarpet::Render::HTML
        OPTIONS = {
          escape_html: true, filter_html: false,
          hard_wrap: true, xhtml: false, safe_links_only: true,
          no_styles: true, no_images: true, no_links: false,
          with_toc_data: false, prettify: false, link_attributes: {}
        }

        STYLES = {}

        STYLES[:header] = [
          "Margin: 0 0 20px 0",
          "padding: 0",
          "font-size: 27px",
          "line-height: 35px",
          "font-weight: bold",
          "color: #0B0C0C;"
        ].join("; ")

        STYLES[:subheader] = [
          "Margin: 0 0 15px 0",
          "padding: 10px 0 0 0",
          "font-size: 19px",
          "line-height: 25px",
          "font-weight: bold",
          "color: #0B0C0C;"
        ].join("; ")

        STYLES[:hrule] = [
          "border: 0",
          "height: 1px",
          "background: #B1B4B6",
          "Margin: 30px 0 30px 0;"
        ].join("; ")

        STYLES[:paragraph] = [
          "Margin: 0 0 20px 0",
          "font-size: 19px",
          "line-height: 25px",
          "color: #0B0C0C;"
        ].join("; ")

        STYLES[:ordered] = [
          "Margin: 0 0 0 20px",
          "padding: 0",
          "list-style-type: decimal;"
        ].join("; ")

        STYLES[:unordered] = [
          "Margin: 0 0 0 20px",
          "padding: 0",
          "list-style-type: disc;"
        ].join("; ")

        STYLES[:list_item] = [
          "Margin: 5px 0 5px",
          "padding: 0 0 0 5px",
          "font-size: 19px",
          "line-height: 25px",
          "color: #0B0C0C;"
        ].join("; ")

        STYLES[:block_quote] = [
          "Margin: 0 0 20px 0",
          "border-left: 10px solid #B1B4B6",
          "padding: 15px 0 0.1px 15px",
          "font-size: 19px",
          "line-height: 25px;"
        ].join("; ")

        STYLES[:link] = [
          "word-wrap: break-word",
          "color: #1D70B8;"
        ].join("; ")

        STYLES[:button] = [
          "box-sizing: border-box",
          "border: 2px solid transparent",
          "box-shadow: 0 2px 0 #003600",
          "color: #FFFFFF",
          "display: inline-block;",
          "font-size: 24px",
          "font-weight: 700",
          "margin-bottom: 30px",
          "padding: 8px 10px 7px",
          "text-decoration: none",
          "background-color: #008800;"
        ].join("; ")

        BUTTON_PATTERN = /\A=(.+)=\z/

        def initialize
          super(OPTIONS)
        end

        def header(text, level)
          if level == 1
            %[<h2 style="#{STYLES[:header]}">#{text}</h2>\n]
          elsif level == 2
            %[<h3 style="#{STYLES[:subheader]}">#{text}</h3>\n]
          else
            paragraph(text)
          end
        end

        def hrule
          %[<hr style="#{STYLES[:hrule]}">\n]
        end

        def paragraph(text)
          %[<p style="#{STYLES[:paragraph]}">#{nl2br(text)}</p>\n]
        end

        def linebreak
          %[<br />\n]
        end

        def list(content, type)
          tag = type == :ordered ? "ol" : "ul"
          style = STYLES[type]

          <<~HTML
            <table role="presentation" style="padding: 0 0 5px 0;">
              <tr>
                <td style="font-family: Helvetica, Arial, sans-serif;">
                  <#{tag} style="#{style}">
                    #{content}
                  </#{tag}>
                </td>
              </tr>
            </table>
          HTML
        end

        def list_item(text, type)
          %[<li style="#{STYLES[:list_item]}">#{text.strip}</li>\n]
        end

        def block_quote(content)
          %[<blockquote style="#{STYLES[:block_quote]}">\n#{content}</blockquote>\n]
        end

        def link(link, title, content)
          if content.match(BUTTON_PATTERN)
            %[<a href="#{link}" style="#{STYLES[:button]}">#{$1}</a>]
          elsif title.present?
            %[<a href="#{link}" title="#{title}" style="#{STYLES[:link]}">#{content}</a>]
          else
            %[<a href="#{link}" style="#{STYLES[:link]}">#{content}</a>]
          end
        end

        def autolink(link, type)
          type == :email ? link : %[<a href="#{link}" style="#{STYLES[:link]}">#{link}</a>]
        end

        %i[
          codespan double_emphasis emphasis
          underline triple_emphasis strikethrough
          superscript highlight quote
        ].each do |method|
          define_method method do |*args|
            args.first
          end
        end

        def nl2br(text)
          text.gsub("\n") { linebreak }
        end
      end

      class Text < Redcarpet::Render::StripDown
        COLUMN_WIDTH = 65

        def header(text, level)
          if level == 1
            text + "\n" + "-" * text.size + "\n"
          else
            paragraph(text)
          end
        end

        def hrule
          "=" * COLUMN_WIDTH + "\n\n"
        end

        def block_quote(content)
          content.chomp.each_line.map { |l| "> " + l }.join + "\n"
        end

        def paragraph(text)
          word_wrap(text) + "\n\n"
        end

        def list(content, type)
          @counter = 0
          content + "\n"
        end

        def list_item(text, type)
          @counter ||= 0
          @counter += 1

          if type == :ordered
            "#{@counter}. #{text.strip}\n"
          else
            "* #{text.strip}\n"
          end
        end

        def link(link, title, content)
          @links ||= []
          @links << link

          "[#{content}][#{@links.size}]"
        end

        def postprocess(text)
          return text unless defined?(@links)
          return text if @links.empty?

          text.chomp + "\n" + footnote_links + "\n"
        end

        private

        def footnote_links
          @links.each_with_index.map(&method(:footnote_link)).join("\n")
        end

        def footnote_link(link, index)
          "[#{index + 1}]: #{link}"
        end

        def word_wrap(text)
          return "" if text.empty?

          pattern = /(.{1,#{COLUMN_WIDTH}})(?:[^\S\n]+\n?|\n*\Z|\n)|\n/
          text.gsub(pattern, "\\1\n").chomp!("\n")
        end
      end

      class Preheader < Text
        def postprocess(text)
          text.squish.truncate_words(50, omission: "")
        end

        def header(text, level)
          paragraph(text)
        end

        def hrule
          ""
        end

        def list_item(text, type)
          text + "\n"
        end
      end
    end

    def markdown_to_html(markup)
      markdown(Renderers::HTML, markup)
    end

    def markdown_to_text(markup)
      markdown(Renderers::Text, markup)
    end

    def markdown_to_preheader(markup)
      markdown(Renderers::Text, markup)
    end

    private

    def markdown_engine(renderer)
      Redcarpet::Markdown.new(renderer.new, MARKDOWN_EXTENSIONS)
    end

    def markdown(renderer, markup)
      markdown_engine(renderer).render(markup.to_s).html_safe
    end
  end
end
