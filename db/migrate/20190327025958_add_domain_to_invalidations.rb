class AddDomainToInvalidations < ActiveRecord::Migration
  def change
    add_column :invalidations, :domain, :string, limit: 255
  end
end
