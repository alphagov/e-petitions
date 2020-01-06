class CreateDefaultDomains < ActiveRecord::Migration[4.2]
  class Domain < ActiveRecord::Base
    has_many :aliases,
      -> { create_with(strip_extension: nil, strip_characters: nil) },
      foreign_key: "canonical_domain_id", class_name: "Domain"
  end

  def up
    gmail = Domain.create!(name: "gmail.com", strip_extension: "+", strip_characters: ".")
    gmail.aliases.create!(name: "googlemail.com")
  end

  def down
    Domain.delete_all
  end
end
