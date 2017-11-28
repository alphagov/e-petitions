class InsertConstituencies < ActiveRecord::Migration[4.2]
  def up
    constituency_ids = ConstituencyPetitionJournal.distinct.pluck(:constituency_id)

    constituency_ids.each do |constituency_id|
      signature = Signature.where(constituency_id: constituency_id).order(nil).first
      signature.constituency if signature
    end
  end

  def down
    Constituency.delete_all
  end
end
