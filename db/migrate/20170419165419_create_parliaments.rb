class CreateParliaments < ActiveRecord::Migration[4.2]
  class Parliament < ActiveRecord::Base; end

  def up
    create_table :parliaments do |t|
      t.datetime :dissolution_at
      t.text :dissolution_message
      t.timestamps null: false
    end

    Parliament.create!(
      dissolution_at: Date.civil(2017, 5, 3).end_of_day,
      dissolution_message: <<-EOF.squish
        The House of Commons has voted in favour of holding an early
        General Election, on Thursday 8 June. This means that Parliament
        will be dissolved at midnight on Wednesday 3 May, and that all
        parliamentary business – including petitions – will stop until
        the new Parliament meets.
      EOF
    )
  end

  def down
    drop_table :parliaments
  end
end
