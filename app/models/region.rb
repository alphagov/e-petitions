class Region < ActiveRecord::Base
  include Translatable

  translate :name

  has_many :constituencies
  has_many :members

  default_scope { preload(:members).order(:id) }
end
