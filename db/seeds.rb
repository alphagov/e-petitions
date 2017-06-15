require './spec/factories'

if Rails.env.development?
  unless AdminUser.where(role: "sysadmin").count > 0
    FactoryGirl.create(:sysadmin_user)
  end

  unless AdminUser.where(role: "moderator").count > 0
    FactoryGirl.create(:moderator_user)
  end

  Admin::Site.first_or_create!
end
