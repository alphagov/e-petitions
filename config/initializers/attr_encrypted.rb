ActiveSupport.on_load(:active_record) do
  require 'attr_encrypted/adapters/active_record'
end
