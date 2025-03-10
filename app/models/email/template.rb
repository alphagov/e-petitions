require 'textacular/searchable'

module Email
  class Template < ActiveRecord::Base
    extend Searchable(:mailer_name, :action_name, :subject, :content)
    include Browseable

    NORMALIZE_SUBJECT = lambda do |subject|
      subject.tap do |s|
        s.encode!(universal_newline: true)
        s.gsub!("\n", " ")
        s.strip!
      end
    end

    NORMALIZE_CONTENT = lambda do |content|
      content.tap do |c|
        c.encode!(universal_newline: true)
        c.gsub!(/ +$/, "")
        c.gsub!(/\b\s*\z/, "\n")
      end
    end

    with_options apply_to_nil: false do
      normalizes :subject, with: NORMALIZE_SUBJECT
      normalizes :content, with: NORMALIZE_CONTENT
    end

    validates :name, presence: true, inclusion: { in: :template_names }
    validates :mailer_name, presence: true, length: { maximum: 50 }
    validates :action_name, presence: true, length: { maximum: 50 }
    validates :action_name, uniqueness: { scope: :mailer_name }
    validates :subject, presence: true, length: { maximum: 200 }
    validates :content, presence: true, length: { maximum: 10000 }

    facet :all, -> { by_name }

    attribute :name

    after_initialize do
      if mailer_name? && action_name?
        self.name = "#{mailer_name}.#{action_name}"
      end
    end

    before_validation do
      self.mailer_name, self.action_name = name.to_s.split('.', 2)
    end

    class << self
      def active
        where(active: true)
      end

      def activate
        update_all(active: true)
      end

      def deactivate
        update_all(active: false)
      end

      def by_name
        order(:mailer_name, :action_name)
      end

      def for(mailer_name, action_name, &block)
        find_or_initialize_by(mailer_name: mailer_name, action_name: action_name).tap(&block)
      end

      def for_mailer(name)
        where(mailer_name: name).order(:action_name)
      end

      def mailer_names
        order(:mailer_name).distinct.pluck(:mailer_name)
      end

      def menu
        I18n.t(:template_menu)
      end

      def existing
        pluck(:mailer_name, :action_name).map { |*args| args.join('.') }
      end

      def template_names
        @template_names ||= menu.flat_map(&:last).map(&:last)
      end

      def load(mailer_name, action_name)
        template_scope.find_by(mailer_name: mailer_name, action_name: action_name)
      end

      def with_all_templates
        Thread.current[:__email_template_scope__] = all
        yield
      ensure
        Thread.current[:__email_template_scope__] = active
      end

      private

      def template_scope
        Thread.current[:__email_template_scope__] ||= active
      end
    end

    delegate :template_names, to: :class

    def reset!
      update!(subject: original_subject, content: original_content)
    end

    def original_subject
      I18n.t(action_name, scope: :"petitions.emails.subjects")
    end

    def original_content
      File.read(Rails.root.join('app', 'views', mailer_name, "#{action_name}.html.erb"))
    end

    def activate
      update(active: true)
    end

    def deactivate
      update(active: false)
    end

    def mailer_description
      I18n.t mailer_name, scope: :mailer_descriptions
    end

    def template_description
      I18n.t action_name, scope: :"template_descriptions.#{mailer_name}"
    end

    def preview(inline = false)
      with_enhanced_formatting(inline || active) do
        self.class.with_all_templates { mailer_preview.call(action_name) }
      end
    end

    def dump
      [action_name, attributes.slice("subject", "content")]
    end

    private

    def mailer_preview
      "#{mailer_name.classify}Preview".constantize
    end

    def with_enhanced_formatting(enabled)
      old_enabled = site.enhanced_email_formatting
      site.enhanced_email_formatting = enabled

      yield
    ensure
      site.enhanced_email_formatting = old_enabled
    end

    def site
      Site.instance
    end
  end
end
