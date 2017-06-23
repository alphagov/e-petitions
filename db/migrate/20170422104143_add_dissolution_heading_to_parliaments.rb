class AddDissolutionHeadingToParliaments < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base; end

  def up
    add_column :parliaments, :dissolution_heading, :string, limit: 100

    parliament = Parliament.first_or_initialize
    parliament.update!(
      dissolution_at: Time.utc(2017, 5, 2, 23, 1, 0),
      dissolution_heading: "All petitions will now close at 00:01am\u00A0on\u00A03\u00A0May\u00A02017",
      dissolution_message: <<-EOF.squish
        There will be an early General Election on Thursday 8 June.
        This means that Parliament has to be dissolved at 00:01am
        (just after midnight) on Wednesday 3 May, and that all
        parliamentary business – including petitions – has to stop.
      EOF
    )
  end

  def down
    remove_column :parliaments, :dissolution_heading
  end
end
