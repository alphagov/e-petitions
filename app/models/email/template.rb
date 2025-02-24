require 'textacular/searchable'

module Email
  class Template < ActiveRecord::Base
    extend Searchable(:mailer_name, :action_name, :subject, :content)
    include Browseable

    validates :name, presence: true, inclusion: { in: :menu }
    validates :mailer_name, presence: true, length: { maximum: 50 }
    validates :action_name, presence: true, length: { maximum: 50 }
    validates :action_name, uniqueness: { scope: :mailer_name }
    validates :subject, presence: true, length: { maximum: 200 }
    validates :content, presence: true, length: { maximum: 10000 }

    facet :all, -> { by_name }

    MAILERS = %w[Archived::PetitionMailer PetitionMailer SponsorMailer]

    attribute :name

    after_find do
      self.name = "#{mailer_name}##{action_name}"
    end

    before_validation do
      self.mailer_name, self.action_name = name.to_s.split('#', 2)
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
        @menu ||= build_menu.sort
      end

      def load(mailer_name, action_name)
        active.find_by(mailer_name: mailer_name, action_name: action_name)
      end

      private

      def build_menu
        MAILERS.flat_map do |mailer_class|
          mailer_class.constantize.yield_self do |mailer|
            mailer.public_instance_methods(false).map do |action_name|
              "#{mailer.mailer_name}##{action_name}"
            end
          end
        end
      end
    end

    def menu
      self.class.menu
    end

    def activate
      update(active: true)
    end

    def deactivate
      update(active: false)
    end

    def dump
      [action_name, attributes.slice("subject", "content")]
    end
  end
end
