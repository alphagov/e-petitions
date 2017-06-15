require 'active_support/deprecation'

module DeprecatedAttributes
  extend ActiveSupport::Concern

  class_methods do
    def deprecate_attribute(*names)
      names.each do |name|
        define_method(:"#{name}") do
          callstack = caller_locations(0).map(&:to_s).reject{ |path| path =~ /deprecated_attributes\.rb/ }
          ActiveSupport::Deprecation.warn("#{self.class.name}##{name} is deprecated and will be removed", callstack)
          super()
        end

        define_method(:"#{name}=") do |value|
          callstack = caller_locations(0).map(&:to_s).reject{ |path| path =~ /deprecated_attributes\.rb/ }
          ActiveSupport::Deprecation.warn("#{self.class.name}##{name}= is deprecated and will be removed", callstack)
          super(value)
        end

        define_method(:"#{name}?") do
          callstack = caller_locations(0).map(&:to_s).reject{ |path| path =~ /deprecated_attributes\.rb/ }
          ActiveSupport::Deprecation.warn("#{self.class.name}##{name}? is deprecated and will be removed", callstack)
          super()
        end
      end
    end
  end
end
