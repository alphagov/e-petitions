class IdentityProvider
  class NotFoundError < ArgumentError; end

  class << self
    delegate :each, to: :providers

    def providers
      @providers ||= load_providers
    end

    def names
      providers.map(&:name)
    end

    def find_by(domain:)
      providers.detect { |provider| provider.domains.include?(domain) }
    end

    def find_by!(name:)
      providers.detect { |provider| provider.name.to_s == name } || raise_provider_not_found(name)
    end

    private

    def load_providers
      Rails.application.config_for(:sso).map { |options| IdentityProvider.new(options) }
    end

    def raise_provider_not_found(name)
      raise NotFoundError, "Couldn’t find the provider '#{name}'"
    end
  end

  attr_reader :name, :strategy
  attr_reader :domains, :roles, :config

  def initialize(options)
    @name = options.fetch(:name).to_sym
    @strategy = options.fetch(:strategy).to_sym
    @domains = options.fetch(:domains)
    @roles = options.fetch(:roles, {})
    @config = options.fetch(:config, {})

    unless strategy_defined?
      raise ArgumentError, "Undefined parent strategy OmniAuth::Strategies::#{@strategy}"
    end

    unless klass_defined?
      strategies.const_set(klass, new_klass)
    end
  end

  def sysadmin
    roles.fetch(:sysadmin, [])
  end

  def moderator
    roles.fetch(:moderator, [])
  end

  def reviewer
    roles.fetch(:reviewer, [])
  end

  def to_param
    name.to_s
  end

  private

  def strategies
    OmniAuth::Strategies
  end

  def parent_klass
    strategies.const_get(strategy)
  end

  def new_klass
    Class.new(parent_klass)
  end

  def klass
    @klass ||= name.to_s.camelize.to_sym
  end

  def klass_defined?
    strategies.const_defined?(klass, false)
  end

  def strategy_defined?
    strategies.const_defined?(strategy, false)
  end
end
