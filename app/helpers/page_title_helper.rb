module PageTitleHelper
  class PageTitleBuilder
    class << self
      def build(template)
        new(template).build
      end
    end

    attr_reader :template

    delegate :assigns, to: :template
    delegate :params, to: :template
    delegate :translate, to: :template
    delegate :[], :has_key?, to: :assigns

    def initialize(template)
      @template = template
    end

    def build
      translate key, options
    end

    private

    def controller
      @controller ||= params[:controller].tr('/', '_')
    end

    def action
      @action ||= params[:action]
    end

    def key
      @key ||= :"#{controller}.#{action}"
    end

    def options
      {}.tap do |opts|
        opts[:scope]        = :page_titles
        opts[:default]      = [:"#{controller}.default", :default]
        opts[:constituency] = constituency.name if constituency?
        opts[:postcode]     = formatted_postcode if postcode?

        if postcode?
          opts[:count] = 1
        else
          opts[:count] = 0
        end

        if petition?
          opts[:petition] = petition.action

          unless petition.is_a?(Archived::Petition)
            opts[:creator] = petition.creator.name
          end
        end
      end
    end

    %w[constituency petition postcode].each do |object|
      define_method :"#{object}?" do
        send(:"#{object}").present?
      end

      define_method :"#{object}" do
        send(:[], object)
      end
    end

    def formatted_postcode
      postcode.gsub(/\A(.+)(.{3})\z/, '\1 \2')
    end
  end

  def page_title
    PageTitleBuilder.build(self)
  end
end
