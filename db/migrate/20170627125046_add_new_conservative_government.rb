class AddNewConservativeGovernment < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base; end

  def up
    Parliament.create!(
      government: "Conservative",
      opening_at: "2017-07-10T12:00:00".in_time_zone,
      dissolution_faq_url: "https://www.parliament.uk/business/committees/committees-a-z/commons-select/petitions-committee/news-parliament-2015/petitions-2017-election--faqs/",
      dissolved_heading: "We're waiting for a new Petitions Committee",
      dissolved_message: "Petitions had to stop because of the recent general election. As soon as a new Petitions Committee is set up by the House of Commons, petitions will start again."
    )
  end

  def down
    parliament = Parliament.find_by!(opening_at: "2017-07-10T12:00:00".in_time_zone)
    parliament.destroy
  end
end
