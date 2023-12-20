class IdentityProvider
  class ProviderNotFound < ArgumentError; end

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
      raise ProviderNotFound, "Couldn't find the provider '#{name}'"
    end
  end

  attr_reader :name, :attribute_statements
  attr_reader :assertion_consumer_service_url, :sp_entity_id
  attr_reader :idp_sso_service_url, :idp_cert, :domains
  attr_reader :sysadmins, :moderators, :reviewers

  def initialize(options)
    @name = options.fetch(:name).to_sym
    @attribute_statements = options.fetch(:attributes, default_attributes)
    @assertion_consumer_service_url = "#{Site.moderate_url}/admin/auth/#{name}/callback"
    @sp_entity_id = "#{Site.moderate_url}/admin/auth/#{name}"
    @idp_sso_service_url = options.fetch(:idp_sso_service_url)
    @idp_cert = options.fetch(:idp_cert, "")
    @domains = options.fetch(:domains)
    @sysadmins = options.fetch(:sysadmins, [])
    @moderators = options.fetch(:moderators, [])
    @reviewers = options.fetch(:reviewers, [])

    unless klass_defined?
      strategies.const_set(klass, new_klass)
    end
  end

  def to_param
    name.to_s
  end

  def config
    {
      attribute_statements: attribute_statements,
      assertion_consumer_service_url: assertion_consumer_service_url,
      sp_entity_id: sp_entity_id,
      idp_sso_service_url: idp_sso_service_url,
      idp_cert: idp_cert
    }
  end

  private

  def default_attributes
    {
      email: ["email"],
      first_name: ["first_name"],
      last_name: ["last_name"],
      groups: ["groups"]
    }
  end

  def strategies
    OmniAuth::Strategies
  end

  def parent_klass
    OmniAuth::Strategies::SAML
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
end
