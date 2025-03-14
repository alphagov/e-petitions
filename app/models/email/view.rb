require 'liquid'

module Email
  class View
    include Email::Markdown

    attr_reader :template, :assigns

    def initialize(template, assigns = {})
      @template, @assigns = template, assigns
    end

    def preheader
      markdown_to_preheader(content)
    end

    def subject
      @subject ||= subject_template.render(assigns)
    rescue Liquid::SyntaxError => error
      error.message
    end

    def html
      markdown_to_html(content)
    end

    def text
      markdown_to_text(content)
    end

    def content
      @content ||= content_template.render(assigns)
    rescue Liquid::SyntaxError => error
      error.message
    end

    private

    def environment
      @environment ||= Liquid::Environment.build do |environment|
        environment.file_system = Email::PartialFileSystem
        environment.register_filter(Email::LiquidFilters)
      end
    end

    def parse_template(source)
      Liquid::Template.parse(source, environment: environment)
    end

    def subject_template
      @subject_template ||= parse_template(template[:subject])
    end

    def content_template
      @content_template ||= parse_template(template[:content])
    end
  end
end
