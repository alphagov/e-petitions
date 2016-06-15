class InsertLocalhostDomain < ActiveRecord::Migration
  class Domain < ActiveRecord::Base; end

  def up
    Domain.create!(name: 'localhost', state: 'block', resolved_at: Time.current)
  end

  def down
    Domain.where(name: 'localhost').delete_all
  end
end
