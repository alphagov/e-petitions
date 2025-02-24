require 'textacular/searchable'

module Email
  class Template < ActiveRecord::Base
    extend Searchable(:mailer_name, :action_name, :subject, :content)
    include Browseable

    validates :name, presence: true, inclusion: { in: :template_names }
    validates :mailer_name, presence: true, length: { maximum: 50 }
    validates :action_name, presence: true, length: { maximum: 50 }
    validates :action_name, uniqueness: { scope: :mailer_name }
    validates :subject, presence: true, length: { maximum: 200 }
    validates :content, presence: true, length: { maximum: 10000 }

    facet :all, -> { by_name }

    attribute :name

    after_find do
      self.name = "#{mailer_name}.#{action_name}"
    end

    before_validation do
      self.mailer_name, self.action_name = name.to_s.split('.', 2)
    end

    class << self
      def active
        where(active: true)
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
        order(:mailer_name).pluck(:mailer_name)
      end

      def menu
        @menu ||= I18n.t(:template_menu)
      end

      def template_names
        @template_names ||= menu.flat_map(&:last).map(&:last)
      end

      def load(mailer_name, action_name)
        active.find_by(mailer_name: mailer_name, action_name: action_name)
      end
    end

    delegate :template_names, to: :class

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

    def preview
      mailer_preview.call(action_name)
    end

    def dump
      [action_name, attributes.slice("subject", "content")]
    end

    private

    def mailer_preview
      "#{mailer_name.classify}Preview".constantize
    end
  end
end
