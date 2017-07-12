ActiveSupport.on_load(:active_record) do
  # This adds support to Arel for `@>` and `&&` array operators
  require 'arel_extensions'
end
