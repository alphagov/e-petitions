require 'i18n/backend/base'

class LanguageBackend
  using I18n::HashRefinements

  module Implementation
    include I18n::Backend::Base

    def available_locales
      Language.available_locales
    end

    def initialized?
      true
    end

    protected

    def lookup(locale, key, scope = [], options = {})
      Language.lookup(locale, key, scope, options)
    end
  end

  include Implementation
end
