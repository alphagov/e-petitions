module TranslationHelper
  class LanguageSwitcherTag
    attr_reader :template

    delegate :link_to, :t, to: :template
    delegate :request, to: :template
    delegate :path_parameters, to: :request
    delegate :query_parameters, to: :request
    delegate :locale, to: :I18n

    def initialize(template)
      @template = template
    end

    def render
      link_to(text, url, class: "language-switcher", title: title, tabindex: -1)
    end

    private

    def text
      t(:text, scope: :"ui.language_switcher")
    end

    def title
      t(:title, scope: :"ui.language_switcher")
    end

    def url
      template.public_send(helper, query_parameters)
    end

    def route
      path_parameters[:route]
    end

    def helper
      locale == :"cy-GB" ? :"#{route}_en_url" : :"#{route}_cy_url"
    end
  end

  def language_switcher_tag
    LanguageSwitcherTag.new(self).render
  end
end
