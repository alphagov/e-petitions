class AddPetitionStatusColumnsToParliament < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base
    class << self
      def current
        where(archived_at: nil).order(created_at: :asc).first!
      end
    end
  end

  def up
    add_column :parliaments, :government_response_heading, :string
    add_column :parliaments, :government_response_description, :text
    add_column :parliaments, :government_response_status, :string
    add_column :parliaments, :parliamentary_debate_heading, :string
    add_column :parliaments, :parliamentary_debate_description, :text
    add_column :parliaments, :parliamentary_debate_status, :string

    Parliament.current.tap do |parliament|
      parliament.update(
        government_response_heading: "Government will respond",
        government_response_description: "Government responds to all petitions that get more than %{count} signatures",
        government_response_status: "Waiting for a new Petitions Committee after the General Election",
        parliamentary_debate_heading: "This petition will be considered for debate",
        parliamentary_debate_description: "All petitions that have more than %{count} signatures will be considered for debate in the new Parliament",
        parliamentary_debate_status: "Waiting for a new Petitions Committee after the General Election"
      )
    end
  end

  def down
    remove_column :parliaments, :government_response_heading
    remove_column :parliaments, :government_response_description
    remove_column :parliaments, :government_response_status
    remove_column :parliaments, :parliamentary_debate_heading
    remove_column :parliaments, :parliamentary_debate_description
    remove_column :parliaments, :parliamentary_debate_status
  end
end
