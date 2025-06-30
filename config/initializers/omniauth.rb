Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = '/admin/auth'
    config.logger = Rails.logger
  end

  IdentityProvider.each do |idp|
    provider idp.name, idp.config
  end
end

# Allow multiple values for attributes
OneLogin::RubySaml::Attributes.single_value_compatibility = false
