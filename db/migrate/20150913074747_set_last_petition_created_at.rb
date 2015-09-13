class SetLastPetitionCreatedAt < ActiveRecord::Migration
  class Petition < ActiveRecord::Base; end
  class Site < ActiveRecord::Base; end

  def up
    Site.update_all(last_petition_created_at: last_petition_created_at)
  end

  def down
    Site.update_all(last_petition_created_at: nil)
  end

  private

  def last_petition_created_at
    Petition.maximum(:created_at) || Time.current
  end
end
