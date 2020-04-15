require 'language_backend'

I18n::Backend::Simple.include(I18n::Backend::Pluralization)

if Site.translation_enabled?
  I18n.backend = I18n::Backend::Chain.new(LanguageBackend.new, I18n.backend)
end
