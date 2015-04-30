# == Schema Information
#
# Table name: trending_petitions
#
#  id                      :integer(4)      not null, primary key
#  petition_id             :integer(4)
#  signatures_in_last_hour :integer(4)      default(0)
#  created_at              :datetime
#  updated_at              :datetime
#

class TrendingPetition < ActiveRecord::Base
  belongs_to :petition

  attr_accessible :petition_id, :signatures_in_last_hour

  def self.update_homepage_trends
    petitions = Petition.last_hour_trending

    transaction do
      destroy_all
      petitions.each do |petition|
        create :petition_id => petition.id,
               :signatures_in_last_hour => petition.signatures_in_last_hour
      end
    end
  end

end
