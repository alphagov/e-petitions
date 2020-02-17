module Translatable
  extend ActiveSupport::Concern

  included do
    class_attribute :translated_methods, default: Set.new

    default_scope do
      extending do
        def where(opts = :chain, *rest)
          opts =
            if opts.is_a?(Hash)
              opts.transform_keys {|k| translated_method_name(k) }
            else
              opts
            end
          super
        end

        def pluck(*names)
          super(*names.map {|k| translated_method_name(k) })
        end
      end
    end
  end

  module ClassMethods
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

    def translated_method_name(k, locale = I18n.locale)
      case k
      when String, Symbol
        if translated_methods.include?(k.to_sym)
          suffix = locale == :"en-GB" ? "_en" : "_cy"
          return (k.to_s + suffix).to_sym
        end
      end
      return k
    end
  end

  private

  def translated_method(english, welsh, *args)
    public_send(I18n.locale == :"en-GB" ? english : welsh, *args)
  end
end
