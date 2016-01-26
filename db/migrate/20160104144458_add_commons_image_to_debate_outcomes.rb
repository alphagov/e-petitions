class AddCommonsImageToDebateOutcomes < ActiveRecord::Migration
  def change
    add_attachment :debate_outcomes, :commons_image
  end
end
