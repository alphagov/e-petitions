module Translatable
  extend ActiveSupport::Concern

  module ClassMethods
    def translate(*names)
      names.each do |name|
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
  end

  private

  def translated_method(english, welsh, *args)
    public_send(I18n.locale == :"en-GB" ? english : welsh, *args)
  end
end
