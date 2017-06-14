require './spec/factories'

if Rails.env.development?
  unless AdminUser.where(role: "sysadmin").count > 0
    FactoryGirl.create(:sysadmin_user)
  end

  unless AdminUser.where(role: "moderator").count > 0
    FactoryGirl.create(:moderator_user)
  end

  # Create some petitions
  [:open_petition, :closed_petition, :rejected_petition].each do |petition_type|
    FactoryGirl.create_list(petition_type, 20)
  end

  [:open, :closed, :rejected].each do |petition_type|
    FactoryGirl.create_list(:archived_petition, 20, petition_type)
  end

  # Create some signatures
  first_id, last_id = Petition.first.id, Petition.last.id

  10.times do
    rand(first_id..last_id).tap do |petition_id|
      FactoryGirl.create_list(:validated_signature, rand(5..10), petition_id: petition_id)
    end
  end
end
