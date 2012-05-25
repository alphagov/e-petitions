require File.expand_path(File.join(File.dirname(__FILE__), 'pickle'))

module Pickle
  class Parser
    @@rb_language = nil

    def set_rb_language
      return if @@rb_language
      @@rb_language = Cucumber::RbSupport::RbDsl.instance_variable_get('@rb_language') ||
        :undefined
    end

    def execute_transforms(arg)
      set_rb_language
      if @@rb_language == :undefined
        arg
      else
        @@rb_language.execute_transforms([arg]).first
      end
    end

    # given a string like 'foo: expr' returns {key => value}
    def parse_field_without_model(field)
      if field =~ /^#{capture_key_and_value_in_field}$/
        value = eval($2)
        if value.respond_to?(:match)
          value = execute_transforms(value)
        end
        { $1 => value }
      else
        raise ArgumentError, "The field argument is not in the correct format.\n\n'#{field}' did not match: #{match_field}"
      end
    end
  end
end

Pickle::Session::Parser.module_eval do

  def parse_hash(hash)
    hash.inject({}) do |parsed, (key, val)|
      if session && val =~ /^#{capture_model}$/
        parsed.merge(key => session.model($1))
      else
        if val.respond_to?(:match)
          parsed.merge(key => execute_transforms(val))
        else
          parsed.merge(key => val)
        end
      end
    end
  end
end
