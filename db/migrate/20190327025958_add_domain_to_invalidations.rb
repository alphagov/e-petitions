class AddDomainToInvalidations < ActiveRecord::Migration[4.2]
  def change
    add_column :invalidations, :domain, :string, limit: 255
  end
end
