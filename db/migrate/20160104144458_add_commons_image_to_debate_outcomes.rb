class AddCommonsImageToDebateOutcomes < ActiveRecord::Migration[4.2]
  def change
    add_attachment :debate_outcomes, :commons_image
  end
end
