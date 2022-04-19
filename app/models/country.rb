class Country < ActiveRecord::Base
  include Translatable

  translate :name

  default_scope { order(:id) }
end
