class LowercaseAdminUserEmails < ActiveRecord::Migration[6.1]
  class AdminUser < ActiveRecord::Base; end

  def change
    up_only do
      AdminUser.find_each do |user|
        user.email = user.email.downcase
      end
    end
  end
end
