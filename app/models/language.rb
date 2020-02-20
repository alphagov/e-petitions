class Language < ActiveRecord::Base
  after_save do
    Site.translations_updated_at!
  end

  class << self
    def table_exists?
      @table_exists ||= connection.table_exists?(table_name)
    rescue ActiveRecord::NoDatabaseError => e
      false
    end

    def before_remove_const
      Thread.current[:__languages__] = nil
    end

    def available_locales
      if table_exists?
        by_name.pluck(:locale).map(&:to_sym)
      else
        []
      end
    end

    def lookup(locale, key, scope, options)
      return nil unless table_exists?

      if translation = translations[locale]
        translation.lookup(locale, key, scope, options)
      end
    end

    def reload_translations
      Thread.current[:__languages__] = nil
    end

    def by_name
      order(name: :asc)
    end

    private

    def translation(locale)
      translations[locale]
    end

    def translations
      Thread.current[:__languages__] ||= translations_hash
    end

    def translations_hash
      Hash.new do |translations, locale|
        translations[locale] = find_by(locale: locale)
      end
    end
  end

  def reload_translations
    update(translations: load_yaml)
  end

  def key?(key, scope = [])
    !lookup(locale, key, scope).nil?
  end

  def get(key, scope = [])
    lookup(locale, key, scope)
  end

  def set(key, value, scope = [])
    keys = normalize_keys(locale, key, scope)
    last_key = keys.pop

    hash = keys.reduce(translations) do |result, k|
      result[k] ||= {}
    end

    hash[last_key] = value.as_json
  end

  def set!(key, value, scope = [])
    set(key, value, scope) && save
  end

  def delete(key, scope = [])
    keys = normalize_keys(locale, key, scope)
    last_key = keys.pop

    hash = keys.reduce(translations) do |result, k|
      if result[k].is_a?(Hash)
        result[k]
      else
        return false
      end
    end

    hash.delete(last_key)
  end

  def delete!(key, scope = [])
    delete(key, scope) && save
  end

  def flatten
    flatten_translation(translations[locale])
  end

  def keys
    flatten.keys.sort
  end

  def lookup(locale, key, scope, options = {})
    keys = normalize_keys(locale, key, scope)

    value = keys.reduce(translations) do |result, k|
      return nil unless result.is_a?(Hash)
      return nil unless result.key?(k)

      result[k]
    end

    case value
    when Hash
      value.deep_symbolize_keys
    else
      value
    end
  end

  def english?
    locale == "en-GB"
  end

  def welsh?
    locale == "cy-GB"
  end

  def translated?(key)
    other_translations.key?(key)
  end

  def changed?(key)
    if value = get(key)
      value != default_value(key)
    end
  end

  private

  def default_value(key)
    simple_backend.translate(locale, key, default: nil)
  end

  def simple_backend
    @simple_backend ||= I18n.backend.backends.last
  end

  def other_locale
    locale == "en-GB" ? "cy-GB" : "en-GB"
  end

  def other_translations
    @other_translations ||= self.class.find_by!(locale: other_locale)
  end

  def load_yaml
    YAML.safe_load(File.read(yaml_file))
  end

  def yaml_file
    Rails.root.join("config", "locales", "ui.#{locale}.yml")
  end

  def flatten_translation(hash, object = {}, parent = nil, separator = ".")
    hash.inject(object) do |memo, (key, value)|
      current = [parent, key].compact.join(separator)

      if value.is_a?(Hash)
        flatten_translation(value, memo, current, separator)
      else
        memo[current] = value
      end

      object
    end
  end

  def normalize_keys(locale, key, scope, separator = ".")
    [].tap do |keys|
      keys.concat normalize_key(locale, separator)
      keys.concat normalize_key(scope, separator)
      keys.concat normalize_key(key, separator)
    end
  end

  def normalize_key(key, separator)
    case key
    when Array
      key.map { |k| normalize_key(k, separator) }.flatten
    else
      keys = key.to_s.split(separator)
      keys.delete('')
      keys.map! do |k|
        case k
        when /\A[-+]?[1-9]\d*\z/ # integer
          k.to_i
        when 'true'
          true
        when 'false'
          false
        else
          k
        end
      end
      keys
    end
  end
end
