module Translatable
  extend ActiveSupport::Concern

  included do
    class_attribute :translated_methods, default: Set.new

    default_scope do
      extending do
        def where(opts = :chain, *rest)
          opts =
            if opts.is_a?(Hash)
              opts.transform_keys { |k| translated_method_name(k) }
            else
              opts
            end
          super
        end

        def pluck(*names)
          super(*names.map { |k| translated_method_name(k) })
        end

        def order(*names)
          super(*names.map { |k| translated_method_name(k) })
        end
      end
    end
  end

  module ClassMethods
    EN_SUFFIX = "_en"
    CY_SUFFIX = "_cy"

    def translate(*names)
      names.each do |name|
        translated_methods << name.to_sym
        class_eval <<~RUBY
          def #{name}
            translated_method(:"#{name}_en", :"#{name}_cy")
          end

          def #{name}?
            translated_method(:"#{name}_en?", :"#{name}_cy?")
          end

          def #{name}=(value)
            translated_method(:"#{name}_en=", :"#{name}_cy=", value)
          end
        RUBY
      end
    end

    def translated_method_name(key)
      case key
      when Hash
        k, dir = key.flatten
        if translated_methods.include?(k)
          return { translated_key(k) => dir }
        end
      when String, Symbol
        if translated_methods.include?(key.to_sym)
          return translated_key(key)
        end
      end
      return key
    end

    private

    def translated_suffix
      I18n.locale == :"en-GB" ? EN_SUFFIX : CY_SUFFIX
    end

    def translated_key(key)
      (key.to_s + translated_suffix).to_sym
    end
  end

  private

  def translated_method(english, welsh, *args)
    public_send(I18n.locale == :"en-GB" ? english : welsh, *args)
  end
end
