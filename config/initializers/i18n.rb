require 'language_backend'

if ENV['TRANSLATION_ENABLED']
  I18n.backend = I18n::Backend::Chain.new(LanguageBackend.new, I18n.backend)
end
