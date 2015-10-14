require 'digest/sha1'
require 'ostruct'

module CacheHelper
  class CacheKey
    class Dependencies
      attr_reader :fragments

      def initialize(fragments)
        @fragments = fragments
      end

      def for(name)
        dependencies_for(name).map{ |d| [d, dependencies_for(d)] }.flatten.uniq
      end

      private

      def dependencies_for(name)
        fragments.fetch(name).fetch(:dependencies, [])
      end
    end

    class Keys
      attr_reader :template

      delegate :assigns, :params, to: :template
      delegate :archived_petition_page?, to: :template
      delegate :create_petition_page?, to: :template
      delegate :home_page?, to: :template
      delegate :last_signature_at, to: :template
      delegate :last_government_response_updated_at, to: :template
      delegate :last_debate_outcome_updated_at, to: :template
      delegate :petition_page?, to: :template
      delegate :page_title, to: :template
      delegate :request, to: :template

      def initialize(template)
        @template = template
      end

      def archived_petition_page
        archived_petition_page?
      end

      def create_petition_page
        create_petition_page?
      end

      def home_page
        home_page?
      end

      def last_petition_created_at
        Site.last_petition_created_at
      end

      def petition
        assigns['petition'] if petition_page?
      end

      def petition_page
        petition_page?
      end

      def reveal_response
        params[:reveal_response] == 'yes'
      end

      def site_updated_at
        Site.updated_at
      end

      def url
        request.original_url
      end

      def for(keys)
        keys.map{ |key| [key, value_for(key)] }.uniq
      end

      def method_missing(name, *args, &block)
        if assigns.key?(name.to_s)
          assigns[name.to_s]
        else
          super
        end
      end

      private

      def value_for(key)
        cache_key_for(public_send(key))
      end

      def cache_key_for(value)
        if value.respond_to?(:cache_key)
          value.cache_key
        elsif Array === value
          value.map{ |v| cache_key_for(v) }.to_param
        elsif Time === value
          value.to_s(:nsec)
        else
          value.to_param
        end
      end
    end

    class Fragment
      attr_reader :keys, :dependencies, :version, :options

      def initialize(fragment)
        @keys         = fragment.fetch(:keys, [])
        @dependencies = fragment.fetch(:dependencies, [])
        @version      = fragment.fetch(:version, 1)
        @options      = fragment.fetch(:options, {})
      end
    end

    attr_reader :template, :name, :fragment
    delegate :options, to: :fragment

    class << self
      def build(template, args)
        new(template, args).build
      end

      def fragments
        @fragments ||= load_yaml.deep_symbolize_keys
      end

      def reset_fragments
        @fragments = nil
      end

      private

      def load_yaml
        YAML.load_file(Rails.root.join('config', 'fragments.yml'))
      end
    end

    def initialize(template, name)
      @template, @name = template, name
      @fragment = Fragment.new(fragments.fetch(name))
    end

    def build
      [cache_key, options]
    end

    private

    def cache_key
      ["#{name}-#{version(name)}", digest].to_param
    end

    def digest
      Digest::SHA1.hexdigest(Hash[digest_keys].to_param)
    end

    def digest_keys
      keys.for(fragment.keys) + dependency_keys
    end

    def dependencies
      @dependencies ||= Dependencies.new(fragments)
    end

    def dependency_keys
      dependencies.for(name).map{ |d| [d, version(d) ] }
    end

    def keys
      @keys ||= Keys.new(template)
    end

    def fragment_keys
      fragment.fetch(:keys, [])
    end

    def fragments
      self.class.fragments
    end

    def version(dependency)
      fragments.fetch(dependency).fetch(:version, 1)
    end
  end

  def cache_for(name, &block)
    cache(*(CacheKey.build(self, name)), &block)
  end

  def last_signature_at
    @_last_signature_at ||= Petition.maximum(:last_signed_at)
  end

  def last_government_response_updated_at
    @_last_government_response_updated_at ||= GovernmentResponse.maximum(:updated_at)
  end

  def last_debate_outcome_updated_at
    @_last_debate_outcome_updated_at ||= DebateOutcome.maximum(:updated_at)
  end
end
