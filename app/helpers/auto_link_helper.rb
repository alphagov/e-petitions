module AutoLinkHelper
  class AutoLinker
    BLANK = "".html_safe
    AUTO_LINK_RE = %r{(?:((?:ftp|http|https|mailto):)//|www\.)[^\s<\u00A0"]+}ix
    AUTO_LINK_CRE = [/<[^>]+$/, /^[^>]*>/, /<a\b.*?>/i, /<\/a>/i]
    AUTO_EMAIL_LOCAL_RE = /[\w.!#\$%&'*\/=?^`{|}~+-]/
    AUTO_EMAIL_RE = /(?<!#{AUTO_EMAIL_LOCAL_RE})[\w.!#\$%+-]\.?#{AUTO_EMAIL_LOCAL_RE}*@[\w-]+(?:\.[\w-]+)+/
    BRACKETS = { "]" => "[", ")" => "(", "}" => "{" }

    attr_reader :template, :text, :options, :block
    delegate :sanitize, :mail_to, :content_tag, to: :template

    def self.generate(template, text, options = {}, &block)
      new(template, text, options, &block).generate
    end

    def initialize(template, text, options, &block)
      @template = template
      @text = text
      @block = block
      @options = options
    end

    def generate
      return BLANK if text.blank?

      result = \
        case scope
        when :urls
          auto_link_urls(sanitized_text)
        when :email_addresses
          auto_link_email_addresses(sanitized_text)
        else
          auto_link_all(sanitized_text)
        end

      sanitize? ? result.html_safe : result
    end

    private

    def scope
      options[:link] || :all
    end

    def sanitized_text
      (sanitize? ? sanitize(text, sanitize_options) : text).to_str
    end

    def sanitize?
      return @sanitize if defined?(@sanitize)
      @sanitize = options[:sanitize] != false
    end

    def sanitize_options
      @sanitize_options ||= options[:sanitize_options] || {}
    end

    def html_options
      @html_options ||= options[:html] || {}
    end

    def auto_linked?(left, right)
      (left =~ AUTO_LINK_CRE[0] && right =~ AUTO_LINK_CRE[1]) ||
      (left.rindex(AUTO_LINK_CRE[2]) && $' !~ AUTO_LINK_CRE[3])
    end

    def auto_link_all(target)
      auto_link_email_addresses(auto_link_urls(target))
    end

    def auto_link_urls(text)
      text.gsub(AUTO_LINK_RE) do
        scheme, href = $1, $&
        punctuation = []

        if auto_linked?($`, $')
          # do not change string; URL is already linked
          href
        else
          # don't include trailing punctuation character as part of the URL
          while href.sub!(/[^\p{Word}\/-=&]$/, "")
            punctuation.push $&

            if opening = BRACKETS[punctuation.last] and href.scan(opening).size > href.scan(punctuation.last).size
              href << punctuation.pop
              break
            end
          end

          link_text = block ? block.call(href) : href
          href = "http://" + href unless scheme

          if sanitize?
            link_text = sanitize(link_text)
            href      = sanitize(href)
          end

          content_tag(:a, link_text, html_options.merge(href: href), sanitize?) + punctuation.reverse.join("")
        end
      end
    end

    def auto_link_email_addresses(text)
      text.gsub(AUTO_EMAIL_RE) do
        text = $&

        if auto_linked?($`, $')
          text.html_safe
        else
          display_text = block ? block.call(text) : text

          if sanitize?
            text         = sanitize(text)
            display_text = sanitize(display_text) unless text == display_text
          end

          mail_to text, display_text, html_options
        end
      end
    end
  end

  def auto_link(text, options = {}, &block)
    AutoLinker.generate(self, text, options, &block)
  end
end